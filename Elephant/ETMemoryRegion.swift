//
//  ETMemoryRegion.swift
//  Elephant
//
//  Created by Nathaniel Symer on 8/10/16.
//  Copyright © 2016 Nathaniel Symer. All rights reserved.
//

import Foundation

public class ETMemoryRegion {
    public var memory: UnsafeMutablePointer<Void>?;
    public var memoryLength: UInt64 = 0;
    
    internal var fileDescriptor: Int32?;
    public var filePath: String?;
    
    var freeSpaces: [ETMemoryRange] = []; // Order Matters
    
    // MARK: Initialization
    
    public init(filePath: String, length: UInt64) {
        self.map(filePath, length: length);
    }
    
    deinit {
        if let mem = self.memory {
            munmap(mem, Int(self.memoryLength ?? 0));
        }
        
        if let fd = self.fileDescriptor {
            close(fd);
        }
    }
    
    // MARK: Memory Allocation Operations
    
    public func vacuum() {
        func f(accum: [ETMemoryRange], mr: ETMemoryRange) -> [ETMemoryRange] {
            if let prev: ETMemoryRange = accum.last {
                if (mr.offset == prev.offset+prev.length) {
                    var accump = accum;
                    accump.removeLast();
                    accump.append(ETMemoryRange(offset: prev.offset, length: prev.length + mr.length));
                    return accump;
                } else {
                    return accum + [mr];
                }
            }
            return [mr];
        }
        self.freeSpaces = self.freeSpaces.reduce([], combine: f);
    }
    
    public func alloc(size: UInt64) -> Bool {
        func getSmallestRange(z: ETMemoryRange?, x: ETMemoryRange) -> ETMemoryRange? {
            if let zp = z {
                if x.length < zp.length {
                    return x;
                }
            }
            return z;
        }
        
        if let smallestRange = (self.freeSpaces.filter { $0.length >= size }.reduce(nil, combine: getSmallestRange)) {
            self.removeFreeMemoryRange(smallestRange);
            return true;
        }
        return false;
    }
    
    public func allocRange(rng: ETMemoryRange) -> Bool {
        for frng in self.freeSpaces {
            if ETMemoryRangesOverlap(rng, b: frng) {
                return false;
            }
        }
        self.removeFreeMemoryRange(rng);
        return true;
    }
    
    public func free(rng: ETMemoryRange) {
        self.addFreeMemoryRange(rng);
        self.set(0, count: Int(rng.length), offset: Int(rng.offset));
        self.sync();
    }
    
    public func freeAll() {
        self.sync();
        self.set(0, count: Int(self.memoryLength), offset: 0);
        self.freeSpaces = [ETMemoryRange(offset: 0, length: self.memoryLength)];
        self.sync();
    }
    
    // MARK: Memory Operations

    public func sync(synchronous: Bool = true) {
        if let mem = self.memory {
            msync(mem, Int(self.memoryLength), synchronous ? MS_SYNC : MS_ASYNC);
        }
    }
    
    public func set(value: Int32, count: Int, offset: Int) {
        if let buf = self.memory {
            memset(buf.advancedBy(offset), value, Int(count));
        }
    }
    
    // copy n bytes from self to region starting at offset.
    public func copyNTo(region: ETMemoryRegion, n: Int, offset: Int = 0) {
        if let from = self.memory {
            if let to = region.memory {
                memcpy(to, from.advancedBy(offset), n);
            }
        }
    }
    
    // MARK: Memory Maps
    
    public func unmap() {
        if let mem = self.memory {
            munmap(mem, Int(self.memoryLength ?? 0));
            self.memory = nil;
            self.memoryLength = 0;
            self.freeSpaces = [];
        }
        
        if let fd = self.fileDescriptor {
            close(fd);
            self.fileDescriptor = nil;
            self.filePath = nil;
        }
    }
    
    public func map(filePath: String, length: UInt64) -> Bool {
        if let (buf, fd) = self.swift_mmap(filePath, length: Int64(length)) {
            self.memory = buf;
            self.memoryLength = length;
            self.fileDescriptor = fd;
            self.filePath = filePath;
            self.freeSpaces = [ETMemoryRange(offset: 0, length: length)];
            return true;
        }
        return false;
    }
    
    public func isMapped() -> Bool {
        return self.memory != nil;
    }
    
    // MARK: Internal Memory Operations

    internal func removeFreeMemoryRange(rng: ETMemoryRange) {
        for i in 0...self.freeSpaces.count {
            let frng = self.freeSpaces[i];
            if frng.length == rng.length && frng.offset == rng.offset {
                if rng.offset + rng.length < self.memoryLength {
                    if let mem = self.memory {
                        memset(mem.advancedBy(Int(rng.offset)), 0, Int(rng.length));
                    }
                }
                
                self.freeSpaces.removeAtIndex(i);
                
                var insertIdx = i;
                
                if rng.offset > frng.offset {
                    let delta = ETMemoryRange(offset: frng.offset, length: rng.offset-frng.offset);
                    self.freeSpaces.insert(delta, atIndex: insertIdx);
                    insertIdx += 1;
                }
                
                let fl = frng.offset + frng.length;
                let l = rng.offset + rng.length;
                
                if l < fl {
                    let delta = ETMemoryRange(offset: l, length: fl - l);
                    self.freeSpaces.insert(delta, atIndex: insertIdx);
                }
                
                break;
            }
        }
    }
    
    internal func addFreeMemoryRange(rng: ETMemoryRange) {
        if var s = self.freeSpaces.first {
            var i = 0;
            
            // find the index/value of the last ETMemoryRange before @rng@
            while (s.offset + s.length) < rng.offset && i < self.freeSpaces.count {
                i += 1;
                s = self.freeSpaces[i];
            }
            
            // if the ranges overlap, combine them
            if s.offset + s.length >= rng.offset {
                self.freeSpaces.insert(ETMemoryRange(offset: s.offset, length: rng.offset + rng.length - s.offset), atIndex: i+1);
            } else {
                self.freeSpaces.insert(rng, atIndex: i+1);
            }
        } else {
            self.freeSpaces = [rng];
        }
    }
    
    // MARK: Internal Memory Mapping Wrapper

    internal func swift_mmap(filePath: String, length: Int64) -> (UnsafeMutablePointer<Void>,Int32)? {
        if let fd: Int32 = getFD((filePath as NSString).fileSystemRepresentation, requiredSize: length) {
            let buf: UnsafeMutablePointer<Void> = mmap(nil, Int(length), PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
            
            let MAP_FAILED: UnsafeMutablePointer<Void> = nil;
            MAP_FAILED.advancedBy(-1);
            
            if isMapFailed(buf) == 1 {
                return nil;
            } else {
                return (buf,fd);
            }
        }
        return nil;
    }
    
    func getFD(filePath: UnsafePointer<Int8>, requiredSize: Int64) -> Int32? {
        errno = 0;
        let fd = open(filePath, O_RDWR | O_CREAT, 0600 as mode_t);
        if fd == -1 { return nil }
        
        var sb = stat();
        
        if fstat(fd, &sb) == -1 || isReg(sb.st_mode) == 0 {
            close(fd);
            return nil;
        }
        
        if requiredSize > sb.st_size {
            if (ftruncate(fd, requiredSize) == -1) {
                close(fd);
                return nil;
            }
        }
        return fd;
    }
}

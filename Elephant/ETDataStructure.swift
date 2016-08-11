//
//  ETDataStructure.swift
//  Elephant
//
//  Created by Nathaniel Symer on 8/10/16.
//  Copyright © 2016 Nathaniel Symer. All rights reserved.
//

import Foundation

public class ETDataStructure {
    public var memory: ETMemoryRegion?;
 
    public required init() {
        self.reallocate();
    }
    
    public required init(memory: ETMemoryRegion) {
        self.memory = memory;
        self.reallocate();
    }
    
    public required init(dataStructure: ETDataStructure) {
        self.memory = dataStructure.memory;
        self.reallocate();
    }
    
    public func reallocate(length: UInt64 = 0) {
        if self.memory?.memoryLength ?? 0 < self.requiredBytes() {
            let filepath = self.dynamicType.makeFilePath();
            let len = length != 0 ? length : pageAlign(self.requiredBytes());
            
            let newMem: ETMemoryRegion = ETMemoryRegion(filePath: filepath, length: len);
            
            if let oldMem = self.memory {
                oldMem.sync();
                oldMem.copyNTo(newMem, n: Int(newMem.memoryLength));
            }
            
            self.memory = newMem;
        }
    }
    
    public func requiredBytes() -> UInt64 {
        return 0;
    }
    
    public class func makeFilePath() -> String {
        return Elephant.shared.dataPath + "/" + NSUUID().UUIDString;
    }
    
    // MARK: Internal
    
    internal func pageAlign(input: UInt64) -> UInt64 {
        let pagesize = UInt64(sysconf(_SC_PAGE_SIZE));
        var v: UInt64 = input;
        let overflow: UInt64 = v % pagesize;
        v -= overflow;
        if overflow > 0 {
            v += pagesize;
        }
        return v;
    }
}

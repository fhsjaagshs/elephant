//
//  ETArray.swift
//  Elephant
//
//  Created by Nathaniel Symer on 8/10/16.
//  Copyright © 2016 Nathaniel Symer. All rights reserved.
//

import Foundation

public class ETArray<T>: ETDataStructure {
    private var elemBuf: UnsafeMutablePointer<T>? {
        get {
            if let b = self.memory?.memory?.advancedBy(sizeof(UInt64)) { return UnsafeMutablePointer<T>(b) }
            return nil
        }
    }
    private var countBuf: UnsafeMutablePointer<UInt64>? {
        get {
            if let b = self.memory?.memory { return UnsafeMutablePointer<UInt64>(b) }
            return nil
        }
    }

    private var capacity: UInt64 = 0;
    
    public var count: UInt64 {
        get { return self.countBuf?[0] ?? 0; }
    }

    public init(capacity: UInt64) {
        self.capacity = capacity;
        super.init();
    }
    
    public required init(dataStructure: ETDataStructure) {
        super.init(dataStructure: dataStructure);
    }
    
    public required init(memory: ETMemoryRegion) {
        super.init(memory: memory);
    }

    override public func requiredBytes() -> UInt64 {
        return UInt64(sizeof(UInt64)) + (self.capacity * UInt64(sizeof(T)));
    }
    
    public subscript(index: Int) -> T {
        get {
            return self.elemBuf!.advancedBy(index * sizeof(T))[0];
        }
        set (v) {
            self.elemBuf!.advancedBy(index * sizeof(T))[0] = v;
        }
    }
}

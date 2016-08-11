//
//  ETMemoryRange.swift
//  Elephant
//
//  Created by Nathaniel Symer on 8/11/16.
//  Copyright © 2016 Nathaniel Symer. All rights reserved.
//

import Foundation

public struct ETMemoryRange {
    var offset: UInt64;
    var length: UInt64;
};

public func ETMemoryRangeMax(range: ETMemoryRange) -> UInt64 {
    return range.offset + range.length;
}

public func ETMemoryRangeEq(from: ETMemoryRange, to: ETMemoryRange) -> Bool {
    return from.length == to.length && from.offset == to.length;
}

public func ETMemoryRangesOverlap(a: ETMemoryRange, b: ETMemoryRange) -> Bool {
    let aoverlap = a.offset < ETMemoryRangeMax(b) && a.offset >= b.offset;
    let boverlap = b.offset < ETMemoryRangeMax(a) && b.offset >= a.offset;
    return aoverlap || boverlap;
}
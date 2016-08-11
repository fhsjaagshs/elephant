//
//  ElephantTests.swift
//  ElephantTests
//
//  Created by Nathaniel Symer on 8/10/16.
//  Copyright © 2016 Nathaniel Symer. All rights reserved.
//

import XCTest
@testable import Elephant

class ElephantTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testArray() {
        Elephant.shared["key"] = ETArray<Int>(capacity: 3);
        
        if let ary: ETArray<Int> = Elephant.shared["key"] as? ETArray<Int> {
            ary[0] = 54;
            ary[1] = 99;
            ary[2] = 45;
        }
        
        if let ary: ETArray<Int> = Elephant.shared["key"] as? ETArray<Int> {
            XCTAssertEqual(ary[0], 54);
            XCTAssertEqual(ary[1], 99);
            XCTAssertEqual(ary[2], 45);
        }
    }
}

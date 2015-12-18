//
//  JSONCorePerformanceTests.swift
//  JSONCore
//
//  Created by Tyrone Trevorrow on 27/10/2015.
//  Copyright © 2015 Tyrone Trevorrow. All rights reserved.
//

import XCTest
import JSONCore

class JSONCorePerformanceTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testPerformanceWithTwoHundredMegabyteFile() {
        let bundle = NSBundle(forClass: self.dynamicType)
        let path = bundle.pathForResource("1", ofType: "json")
        let data = NSData(contentsOfFile: path!)!
        let json = String.fromCString(unsafeBitCast(data.bytes, UnsafePointer<CChar>.self))!
        measureBlock {
            do {
                let value = try JSONParser.parseData(json.unicodeScalars)
                let coordinates = value.object!["coordinates"]!.array!
                let len = coordinates.count
                var x = 0.0; var y = 0.0; var z = 0.0
                
                for coord in coordinates {
                    x = x + (coord.object!["x"]!.double!)
                    y = y + (coord.object!["y"]!.double!)
                    z = z + (coord.object!["z"]!.double!)
                }
                print("\(x / Double(len))")
                print("\(y / Double(len))")
                print("\(z / Double(len))")
            } catch let err {
                if let printableError = err as? CustomStringConvertible {
                    XCTFail("JSON parse error: \(printableError)")
                }
            }
        }
    }
}

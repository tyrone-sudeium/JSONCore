//
//  JSONCoreTests.swift
//  JSONCoreTests
//
//  Created by Tyrone Trevorrow on 23/10/2015.
//  Copyright © 2015 Tyrone Trevorrow. All rights reserved.
//

import XCTest
import JSONCore

class JSONCoreTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSanity() {
        let json = "{\"function\":null,\"numbers\":[4,8,15,16,23,42],\"y_index\":2,\"x_index\":12,\"z_index\":5,\"arcs\":[{\"p2\":[22.1,50],\"p1\":[10.5,15.5],\"radius\":5},{\"p2\":[23.1,40],\"p1\":[11.5,15.5],\"radius\":10},{\"p2\":[23.1,30],\"p1\":[12.5,15.5],\"radius\":3},{\"p2\":[24.1,20],\"p1\":[13.5,15.5],\"radius\":2},{\"p2\":[25.1,10],\"p1\":[14.5,15.5],\"radius\":8},{\"p2\":[26.1,0],\"p1\":[15.5,15.5],\"radius\":2}],\"label\":\"my label\"}"
        do {
            try JSONParser.parseData(json.unicodeScalars)
        } catch let err {
            if let printableError = err as? CustomStringConvertible {
                XCTFail("JSON parse error: \(printableError)")
            }
        }
    }
    
    func testPerformanceWithTwoHundredMegabyteFile() {
        measureBlock {
            let bundle = NSBundle(forClass: self.dynamicType)
            let path = bundle.pathForResource("1", ofType: "json")
            let json = try! String(contentsOfFile: path!)
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

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
    
    let jsonString: String = {
        let bundle = Bundle(for: JSONCorePerformanceTests.self)
        let path = bundle.path(forResource: "1", ofType: "json")
        let data = NSData(contentsOfFile: path!)!
        let jsonString = String(cString: unsafeBitCast(data.bytes, to: UnsafePointer<CChar>.self))
        
        return jsonString
    }()
    
    var json: JSON?
    
    func testParsePerformanceWithTwoHundredMegabyteFile() {
        measure {
            do {
                self.json = try JSONParser.parse(scalars: self.jsonString.unicodeScalars)
                let coordinates = self.json!.object!["coordinates"]!.array!
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
    
    func testSerializerSpeed() {
        if json == nil {
            json = try! JSONParser.parse(string: self.jsonString)
        }
        
        measure {
            let _ = try! JSONSerializer.serialize(value: self.json!)
        }
    }
    
    func testSerializerSpeedPrettyPrinting() {
        if json == nil {
            json = try! JSONParser.parse(string: self.jsonString)
        }
        
        measure {
            let _ = try! JSONSerializer.serialize(value: self.json!, prettyPrint: true)
        }
    }
}

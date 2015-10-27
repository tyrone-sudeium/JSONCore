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
    
    func expectError(error: JSONParseError, json: String, file: String = __FILE__, line: UInt = __LINE__) {
        do {
            try JSONParser.parseData(json.unicodeScalars)
            XCTFail("Expected error, got success", file: file, line: line)
        } catch let err {
            XCTAssertEqual((err as! JSONParseError), error, file: file, line: line)
        }
    }
    
    func expectErrorString(error: String, json: String, file: String = __FILE__, line: UInt = __LINE__) {
        do {
            try JSONParser.parseData(json.unicodeScalars)
            XCTFail("Expected error, got success", file: file, line: line)
        } catch let err {
            if let printableError = err as? CustomStringConvertible {
                let str = printableError.description
                XCTAssertEqual(str, error, file: file, line: line)
            }
        }
    }
    
    func expectValue(value: JSONValue, json: String, file: String = __FILE__, line: UInt = __LINE__) {
        do {
            let parsedValue = try JSONParser.parseData(json.unicodeScalars)
            XCTAssertEqual(value, parsedValue, file: file, line: line)
        } catch let err {
            if let printableError = err as? CustomStringConvertible {
                XCTFail("JSON parse error: \(printableError)", file: file, line: line)
            }
        }
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
    
    func testEmptyInput() {
        expectError(.EmptyInput, json: "")
        expectError(.EmptyInput, json: "   ")
    }
    
    func testParseBool() {
        expectValue(.JSONBool(true), json: "true")
        expectValue(.JSONBool(false), json: "false")
        expectError(.UnexpectedCharacter(lineNumber: 0, characterNumber: 5), json: "truex")
        expectError(.UnexpectedCharacter(lineNumber: 0, characterNumber: 6), json: "falsex")
        expectError(.UnexpectedKeyword(lineNumber: 0, characterNumber: 1), json: "tru")
        expectError(.UnexpectedKeyword(lineNumber: 0, characterNumber: 1), json: "fals")
    }
    
    func testParseNumbers() {
        expectValue(.JSONNumber(.JSONIntegral(0)), json: "0")
        expectValue(.JSONNumber(.JSONIntegral(9223372036854775807)), json: "9223372036854775807")
        expectValue(.JSONNumber(.JSONIntegral(-9223372036854775808)), json: "-9223372036854775808")
        expectValue(.JSONNumber(.JSONFractional(1.0)), json: "10e-1")
        expectValue(.JSONNumber(.JSONFractional(0.1)), json: "0.1")
        // Floating point numbers are the actual worst
        expectValue(.JSONNumber(.JSONFractional(0.000000050000000000000011)), json: "5e-8")
        expectValue(.JSONNumber(.JSONFractional(0.1)), json: "0.1")
        expectValue(.JSONNumber(.JSONFractional(0.52)), json: "5.2e-1")
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

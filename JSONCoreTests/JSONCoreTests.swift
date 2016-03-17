//
//  JSONCoreTests.swift
//  JSONCoreTests
//
//  Created by Tyrone Trevorrow on 23/10/2015.
//  Copyright © 2015 Tyrone Trevorrow. All rights reserved.
//

import XCTest
import JSONCore
import Foundation

extension JSONParseError: Equatable {
}
public func == (lhs: JSONParseError, rhs: JSONParseError) -> Bool {
    switch (lhs, rhs) {
    case (.Unknown, .Unknown): return true
    case (.EmptyInput, .EmptyInput): return true
    case (.UnterminatedString, .UnterminatedString): return true
    case (.InvalidUnicode, .InvalidUnicode): return true
    case (.EndOfFile, .EndOfFile): return true
    case let (.UnexpectedCharacter(lineLHS, charLHS), .UnexpectedCharacter(lineRHS, charRHS)):
        return lineLHS == lineRHS && charLHS == charRHS
    case let (.UnexpectedKeyword(lineLHS, charLHS), .UnexpectedKeyword(lineRHS, charRHS)):
        return lineLHS == lineRHS && charLHS == charRHS
    case let (.InvalidNumber(lineLHS, charLHS), .InvalidNumber(lineRHS, charRHS)):
        return lineLHS == lineRHS && charLHS == charRHS
    default: return false
        
    }
}

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
            try JSONParser.parse(json.unicodeScalars)
            XCTFail("Expected error, got success", file: file, line: line)
        } catch let err {
            XCTAssertEqual((err as! JSONParseError), error, file: file, line: line)
        }
    }
    
    func expectErrorString(error: String, json: String, file: String = __FILE__, line: UInt = __LINE__) {
        do {
            try JSONParser.parse(json.unicodeScalars)
            XCTFail("Expected error, got success", file: file, line: line)
        } catch let err {
            if let printableError = err as? CustomStringConvertible {
                let str = printableError.description
                XCTAssertEqual(str, error, file: file, line: line)
            }
        }
    }
    
    func expectValue(value: JSON, json: String, file: String = __FILE__, line: UInt = __LINE__) {
        do {
            let parsedValue = try JSONParser.parse(json.unicodeScalars)
            XCTAssertEqual(value, parsedValue, file: file, line: line)
        } catch let err {
            if let printableError = err as? CustomStringConvertible {
                XCTFail("JSON parse error: \(printableError)", file: file, line: line)
            }
        }
    }
    
    func expectString(string: String, json: JSON, file: String = __FILE__, line: UInt = __LINE__) {
        do {
            let serialized = try json.jsonString()
            XCTAssertEqual(string, serialized, file: file, line: line)
        } catch let err {
            if let printableError = err as? CustomStringConvertible {
                XCTFail("JSON serialization error: \(printableError)", file: file, line: line)
            }
        }
    }
    
    func testSanity() {
        let json = "{\"function\":null,\"numbers\":[4,8,15,16,23,42],\"y_index\":2,\"x_index\":12,\"z_index\":5,\"arcs\":[{\"p2\":[22.1,50],\"p1\":[10.5,15.5],\"radius\":5},{\"p2\":[23.1,40],\"p1\":[11.5,15.5],\"radius\":10},{\"p2\":[23.1,30],\"p1\":[12.5,15.5],\"radius\":3},{\"p2\":[24.1,20],\"p1\":[13.5,15.5],\"radius\":2},{\"p2\":[25.1,10],\"p1\":[14.5,15.5],\"radius\":8},{\"p2\":[26.1,0],\"p1\":[15.5,15.5],\"radius\":2}],\"label\":\"my label\"}"
        do {
            try JSONParser.parse(json.unicodeScalars)
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
        expectValue(.bool(true), json: "true")
        expectValue(.bool(false), json: "false")
        expectError(.UnexpectedCharacter(lineNumber: 0, characterNumber: 5), json: "truex")
        expectError(.UnexpectedCharacter(lineNumber: 0, characterNumber: 6), json: "falsex")
        expectError(.UnexpectedKeyword(lineNumber: 0, characterNumber: 1), json: "tru")
        expectError(.UnexpectedKeyword(lineNumber: 0, characterNumber: 1), json: "fals")
    }
    
    func testParseNumbers() {
        expectValue(.integer(0), json: "0")
        expectValue(.integer(9223372036854775807), json: "9223372036854775807")
        expectValue(.integer(-9223372036854775808), json: "-9223372036854775808")
        expectValue(.double(1.0), json: "10e-1")
        expectValue(.double(0.1), json: "0.1")
        // Floating point numbers are the actual worst
        expectValue(.double(0.000000050000000000000011), json: "5e-8")
        expectValue(.double(0.1), json: "0.1")
        expectValue(.double(0.52), json: "5.2e-1")
    }
    
    func testParseUnicode() {
        expectValue(.string("и"), json: "\"\\u0438\"")
        expectValue(.string("𝄞"), json: "\"\\ud834\\udd1e\"")
    }
    
    func testSerializeBool() {
        expectString("true", json: JSON.bool(true))
        expectString("false", json: JSON.bool(false))
    }
    
    func testSerializeNumber() {
        expectString("0", json: JSON.integer(0))
        expectString("9223372036854775807", json: JSON.integer(9223372036854775807))
        expectString("-9223372036854775808", json: JSON.integer(-9223372036854775808))
        expectString("0.1", json: JSON.double(0.1))
        expectString("10.01", json: JSON.double(10.01))
    }
    
    func testSerializeNull() {
        expectString("null", json: JSON.null)
    }
    
    func testSerializeString() {
        expectString("\"test\"", json: JSON.string("test"))
        expectString("\"test 1, test 2\"", json: JSON.string("test 1, test 2"))
        expectString("\"Привет\"", json: JSON.string("Привет"))
        expectString("\"𝄞\"", json: JSON.string("𝄞"))
    }
    
    func testSerializeStringEscapes() {
        expectString("\"\\r\\n\\t\\\\/\"", json: JSON.string("\r\n\t\\/"))
        let backspace = UnicodeScalar(0x0008)
        var backspaceStr = ""
        backspaceStr.append(backspace)
        expectString("\"\\b\"", json: JSON.string(backspaceStr))
    }
    
    func testSerializeUnicodeEscapes() {
        expectString("\"\\u001f\"", json: "\u{001F}" as JSON)
        expectString("\"\\u0000\"", json: "\u{0000}" as JSON)
        expectString("\"\\u001c\"", json: "\u{001C}" as JSON)
        
    }
    
    func testSerializeArray() {
        let arr: JSON = [
            1, 2.1, true, false, "x", nil
        ]
        let nestedArr: JSON = [arr]
        expectString("[1,2.1,true,false,\"x\",null]", json: arr)
        expectString("[[1,2.1,true,false,\"x\",null]]", json: nestedArr)
    }
    
    func testSerializeObject() {
        let obj: JSON = [
            "integral": 1,
            "doubleal": 2.1,
            "true": true,
            "false": false,
            "str": "x",
            "null": nil
        ]
        let str = try! obj.jsonString()
        let returnedObj = try! JSONParser.parse(str.unicodeScalars)
        XCTAssertEqual(returnedObj, obj)
    }
    
    func testPrettyPrintNestedArray() {
        let arr: JSON = [
            [1, 2, 3],
            [4, 5, 6]
        ]
        let expected = "[\n  [\n    1,\n    2,\n    3\n  ],\n  [\n    4,\n    5,\n    6\n  ]\n]"
        let str = try! arr.jsonString()
        XCTAssertEqual(str, expected)
    }
    
    func testPrettyPrintNestedObjects() {
        let obj: JSON = [
            "test": [
                "1": 2
            ]
        ]
        let expected = "{\n  \"test\": {\n    \"1\": 2\n  }\n}"
        let str = try! obj.jsonString()
        XCTAssertEqual(str, expected)
    }
    
    func testSubscriptGetter() {
        var json: JSON = [
            "name": "Ethan",
            "yob": 1995,
            "computer": [
                "purchased": 2013,
                "ports": [
                    "usb1",
                    "usb2",
                    "thunderbolt1",
                    "thunderbolt2"
                ],
                "memory": [
                    "capacity": 8,
                    "clock": 1.6,
                    "type": "DDR3"
                ]
            ]
        ]
        
        let jsonString = try! json.jsonString()
        
        let json2 = try! JSONParser.parse(jsonString)
        
        XCTAssertEqual(json, json2)
        
        XCTAssertEqual(json["yob"].int, 1995)
        XCTAssertEqual(json["computer"]["purchased"].int, 2013)
        XCTAssertEqual(json["computer"]["memory"]["type"].string, "DDR3")
        XCTAssertEqual(json["computer"]["memory"]["type"].string, "DDR3")
        XCTAssertEqual(json["computer"]?["memory"]?["type"].string, "DDR3")
        XCTAssertEqual(json["computer"]["ports"][1].string, "usb2")
        XCTAssertEqual(json["computer"]["ports"][-1].string, nil)
    }
    
    func testSubscriptSetter() {
        var json: JSON = ["height": 1.90, "array": [1, 2, 3]]
        XCTAssertEqual(json["height"].double, 1.90)
        json["height"] = 1.91
        XCTAssertEqual(json["height"].double, 1.91)
        
        XCTAssertEqual(json["array"][0], 1)
        json["array"][0] = 4
        XCTAssertEqual(json["array"][0], 4)
    }
}

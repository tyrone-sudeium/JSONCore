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
    
    func expectString(string: String, json: JSONValue, file: String = __FILE__, line: UInt = __LINE__) {
        do {
            let serialized = try JSONSerializer.serializeValue(json, prettyPrint: false)
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
    
    func testParseUnicode() {
        expectValue(.JSONString("и"), json: "\"\\u0438\"")
        expectValue(.JSONString("𝄞"), json: "\"\\ud834\\udd1e\"")
    }
    
    func testSerializeBool() {
        expectString("true", json: JSONValue.JSONBool(true))
        expectString("false", json: JSONValue.JSONBool(false))
    }
    
    func testSerializeNumber() {
        expectString("0", json: JSONValue.JSONNumber(.JSONIntegral(0)))
        expectString("9223372036854775807", json: JSONValue.JSONNumber(.JSONIntegral(9223372036854775807)))
        expectString("-9223372036854775808", json: JSONValue.JSONNumber(.JSONIntegral(-9223372036854775808)))
        expectString("0.1", json: JSONValue.JSONNumber(.JSONFractional(0.1)))
        expectString("10.01", json: JSONValue.JSONNumber(.JSONFractional(10.01)))
    }
    
    func testSerializeNull() {
        expectString("null", json: JSONValue.JSONNull)
    }
    
    func testSerializeString() {
        expectString("\"test\"", json: JSONValue.JSONString("test"))
        expectString("\"test 1, test 2\"", json: JSONValue.JSONString("test 1, test 2"))
        expectString("\"Привет\"", json: JSONValue.JSONString("Привет"))
        expectString("\"𝄞\"", json: JSONValue.JSONString("𝄞"))
    }
    
    func testSerializeStringEscapes() {
        expectString("\"\\r\\n\\t\\\\/\"", json: JSONValue.JSONString("\r\n\t\\/"))
        let backspace = UnicodeScalar(0x0008)
        var backspaceStr = ""
        backspaceStr.append(backspace)
        expectString("\"\\b\"", json: JSONValue.JSONString(backspaceStr))
    }
    
    func testSerializeUnicodeEscapes() {
        expectString("\"\\u001f\"", json: "\u{001F}" as JSONValue)
        expectString("\"\\u0000\"", json: "\u{0000}" as JSONValue)
        expectString("\"\\u001c\"", json: "\u{001C}" as JSONValue)
        
    }
    
    func testSerializeArray() {
        let arr: JSONValue = [
            1, 2.1, true, false, "x", nil
        ]
        let nestedArr: JSONValue = [arr]
        expectString("[1,2.1,true,false,\"x\",null]", json: arr)
        expectString("[[1,2.1,true,false,\"x\",null]]", json: nestedArr)
    }
    
    func testSerializeObject() {
        let obj: JSONValue = [
            "integral": 1,
            "fractional": 2.1,
            "true": true,
            "false": false,
            "str": "x",
            "null": nil
        ]
        let str = try! JSONSerializer.serializeValue(obj, prettyPrint: false)
        let returnedObj = try! JSONParser.parseData(str.unicodeScalars)
        XCTAssertEqual(returnedObj, obj)
    }
    
    func testPrettyPrintNestedArray() {
        let arr: JSONValue = [
            [1, 2, 3],
            [4, 5, 6]
        ]
        let expected = "[\n  [\n    1,\n    2,\n    3\n  ],\n  [\n    4,\n    5,\n    6\n  ]\n]"
        let str = try! JSONSerializer.serializeValue(arr, prettyPrint: true)
        XCTAssertEqual(str, expected)
    }
    
    func testPrettyPrintNestedObjects() {
        let obj: JSONValue = [
            "test": [
                "1": 2
            ]
        ]
        let expected = "{\n  \"test\": {\n    \"1\": 2\n  }\n}"
        let str = try! JSONSerializer.serializeValue(obj, prettyPrint: true)
        XCTAssertEqual(str, expected)
    }
}

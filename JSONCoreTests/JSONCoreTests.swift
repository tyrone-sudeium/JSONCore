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
    case (.unknown, .unknown): return true
    case (.emptyInput, .emptyInput): return true
    case (.unterminatedString, .unterminatedString): return true
    case (.invalidUnicode, .invalidUnicode): return true
    case (.endOfFile, .endOfFile): return true
    case let (.unexpectedCharacter(lineLHS, charLHS), .unexpectedCharacter(lineRHS, charRHS)):
        return lineLHS == lineRHS && charLHS == charRHS
    case let (.unexpectedKeyword(lineLHS, charLHS), .unexpectedKeyword(lineRHS, charRHS)):
        return lineLHS == lineRHS && charLHS == charRHS
    case let (.invalidNumber(lineLHS, charLHS), .invalidNumber(lineRHS, charRHS)):
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
    
    func expect(error: JSONParseError, json: String, file: StaticString = #file, line: UInt = #line) {
        do {
            let _ = try JSONParser.parse(scalars: json.unicodeScalars)
            XCTFail("Expected error, got success", file: file, line: line)
        } catch let err {
            XCTAssertEqual((err as! JSONParseError), error, file: file, line: line)
        }
    }
    
    func expect(errorString: String, json: String, file: StaticString = #file, line: UInt = #line) {
        do {
            let _ = try JSONParser.parse(scalars: json.unicodeScalars)
            XCTFail("Expected error, got success", file: file, line: line)
        } catch let err {
            if let printableError = err as? CustomStringConvertible {
                let str = printableError.description
                XCTAssertEqual(str, errorString, file: file, line: line)
            }
        }
    }
    
    func expect(value: JSON, json: String, file: StaticString = #file, line: UInt = #line) {
        do {
            let parsedValue = try JSONParser.parse(scalars: json.unicodeScalars)
            XCTAssertEqual(value, parsedValue, file: file, line: line)
        } catch let err {
            if let printableError = err as? CustomStringConvertible {
                XCTFail("JSON parse error: \(printableError)", file: file, line: line)
            }
        }
    }
    
    func expect(string: String, json: JSON, file: StaticString = #file, line: UInt = #line) {
        do {
            let serialized = try json.serialized()
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
            let _ = try JSONParser.parse(scalars: json.unicodeScalars)
        } catch let err {
            if let printableError = err as? CustomStringConvertible {
                XCTFail("JSON parse error: \(printableError)")
            }
        }
    }
    
    func testEmptyInput() {
        expect(error: .emptyInput, json: "")
        expect(error: .emptyInput, json: "   ")
    }
    
    func testParseBool() {
        expect(value: .bool(true), json: "true")
        expect(value: .bool(false), json: "false")
        expect(error: .unexpectedCharacter(lineNumber: 0, characterNumber: 5), json: "truex")
        expect(error: .unexpectedCharacter(lineNumber: 0, characterNumber: 6), json: "falsex")
        expect(error: .unexpectedKeyword(lineNumber: 0, characterNumber: 1), json: "tru")
        expect(error: .unexpectedKeyword(lineNumber: 0, characterNumber: 1), json: "fals")
    }
    
    func testParseNumbers() {
        expect(value: .integer(0), json: "0")
        expect(value: .integer(9223372036854775807), json: "9223372036854775807")
        expect(value: .integer(-9223372036854775808), json: "-9223372036854775808")
        expect(value: .double(1.0), json: "10e-1")
        expect(value: .double(0.1), json: "0.1")
        // Floating point numbers are the actual worst
        expect(value: .double(0.000000050000000000000011), json: "5e-8")
        expect(value: .double(0.1), json: "0.1")
        expect(value: .double(0.52), json: "5.2e-1")
    }
    
    func testParseUnicode() {
        expect(value: .string("и"), json: "\"\\u0438\"")
        expect(value: .string("𝄞"), json: "\"\\ud834\\udd1e\"")
    }
    
    func testParseArray() {
        expect(value: .array([]), json: "[\n  \n]")
        expect(value: .array([]), json: "[\n]")
    }
    
    func testSerializeBool() {
        expect(string: "true", json: JSON.bool(true))
        expect(string: "false", json: JSON.bool(false))
    }
    
    func testSerializeNumber() {
        expect(string: "0", json: JSON.integer(0))
        expect(string: "9223372036854775807", json: JSON.integer(9223372036854775807))
        expect(string: "-9223372036854775808", json: JSON.integer(-9223372036854775808))
        expect(string: "0.1", json: JSON.double(0.1))
        expect(string: "10.01", json: JSON.double(10.01))
    }
    
    func testSerializeNull() {
        expect(string: "null", json: JSON.null)
    }
    
    func testSerializeString() {
        expect(string: "\"test\"", json: JSON.string("test"))
        expect(string: "\"test 1, test 2\"", json: JSON.string("test 1, test 2"))
        expect(string: "\"Привет\"", json: JSON.string("Привет"))
        expect(string: "\"𝄞\"", json: JSON.string("𝄞"))
    }
    
    func testSerializeStringEscapes() {
        expect(string: "\"\\r\\n\\t\\\\/\"", json: JSON.string("\r\n\t\\/"))
        let backspace = UnicodeScalar(0x0008)!
        var backspaceStr = ""
        backspaceStr.unicodeScalars.append(backspace)
        expect(string: "\"\\b\"", json: JSON.string(backspaceStr))
    }
    
    func testSerializeUnicodeEscapes() {
        expect(string: "\"\\u001f\"", json: "\u{001F}" as JSON)
        expect(string: "\"\\u0000\"", json: "\u{0000}" as JSON)
        expect(string: "\"\\u001c\"", json: "\u{001C}" as JSON)
        
    }
    
    func testSerializeArray() {
        let arr: JSON = [
            1, 2.1, true, false, "x", JSON.null
        ]
        let nestedArr: JSON = [arr]
        expect(string: "[1,2.1,true,false,\"x\",null]", json: arr)
        expect(string: "[[1,2.1,true,false,\"x\",null]]", json: nestedArr)
    }
    
    func testSerializeObject() {
        let obj: JSON = [
            "integral": 1,
            "doubleal": 2.1,
            "true": true,
            "false": false,
            "str": "x",
            "null": JSON.null
        ]
        let str = try! obj.serialized()
        let returnedObj = try! JSONParser.parse(scalars: str.unicodeScalars)
        XCTAssertEqual(returnedObj, obj)
    }
    
    func testPrettyPrintNestedArray() {
        let arr: JSON = [
            [1, 2, 3] as JSON,
            [4, 5, 6] as JSON
        ]
        let expected = "[\n  [\n    1,\n    2,\n    3\n  ],\n  [\n    4,\n    5,\n    6\n  ]\n]"
        let str = try! arr.serialized(prettyPrint: true)
        XCTAssertEqual(str, expected)
    }
    
    func testPrettyPrintNestedObjects() {
        let obj: JSON = [
            "test": [
                "1": 2
            ] as JSON
        ]
        let expected = "{\n  \"test\": {\n    \"1\": 2\n  }\n}"
        let str = try! obj.serialized(prettyPrint: true)
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
                ] as JSON,
                "memory": [
                    "capacity": 8,
                    "clock": 1.6,
                    "type": "DDR3"
                ] as JSON
            ] as JSON
        ]
        
        let jsonString = try! json.serialized()
        
        let json2 = try! JSONParser.parse(string: jsonString)
        
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
        var json: JSON = ["height": 1.90, "array": [1, 2, 3] as JSON]
        XCTAssertEqual(json["height"].double, 1.90)
        json["height"] = 1.91
        XCTAssertEqual(json["height"].double, 1.91)
        
        XCTAssertEqual(json["array"][0], 1)
        json["array"][0] = 4
        XCTAssertEqual(json["array"][0], 4)
    }
    
    func testArrayLiteralConversion() {
        enum Color: String, JSONEncodable {
            case Red, Green, Blue
            
            func encodedToJSON() -> JSON {
                return JSON.string(rawValue)
            }
        }
        
        struct Person: JSONEncodable {
            var name: String
            var favoriteColor: Color
            
            func encodedToJSON() -> JSON {
                return ["name": name, "favoriteColor": favoriteColor]
            }
        }
        
        let bob = Person(name: "Bob Doe", favoriteColor: .Green)
        
        let json: JSON = ["name": bob.name, "favoriteColor": bob.favoriteColor]
        
        XCTAssertEqual(json, bob.encodedToJSON())
    }
}

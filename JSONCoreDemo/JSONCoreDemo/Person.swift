//
//  Person.swift
//  JSONCoreDemo
//
//  Created by Tyrone Trevorrow on 3/12/2015.
//  Copyright © 2015 Tyrone Trevorrow. All rights reserved.
//

import Foundation
import JSONCore

struct Person: JSONConvertible {
    let firstName: String
    let surname: String
    let nicknames: [String]
    let age: Int64
    
    init(jsonValue: JSONValue) throws {
        guard let firstName = jsonValue.object?["firstName"]?.string else { throw JSONConvertError.MissingField(field: "firstName") }
        guard let surname = jsonValue.object?["surname"]?.string else { throw JSONConvertError.MissingField(field: "surname") }
        guard let nicknames = jsonValue.object?["nicknames"]?.array else { throw JSONConvertError.MissingField(field: "nicknames") }
        guard let age = jsonValue.object?["age"]?.int else { throw JSONConvertError.MissingField(field: "age") }
        self.firstName = firstName
        self.surname = surname
        self.age = age
        self.nicknames = try nicknames.map { value -> String in
            guard let s = value.string else { throw JSONConvertError.InvalidField(field: "nicknames")}
            return s
        }
    }
    
    init(firstName: String, surname: String, nicknames: [String], age: Int64) {
        self.firstName = firstName
        self.surname = surname
        self.nicknames = nicknames
        self.age = age
    }
    
    func jsonValue() throws -> JSONValue {
        var value = JSONObject()
        value["firstName"] = JSONValue.JSONString(firstName)
        value["surname"] = JSONValue.JSONString(surname)
        value["age"] = JSONValue.JSONNumber(JSONNumberType.JSONIntegral(age))
        value["nicknames"] = JSONValue.JSONArray(self.nicknames.map { JSONValue.JSONString($0) })
        return JSONValue.JSONObject(value)
    }
}

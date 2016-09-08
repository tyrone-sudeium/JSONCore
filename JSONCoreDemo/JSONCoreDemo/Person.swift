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
    let age: Int
    
    init(jsonValue: JSON) throws {
        guard let firstName = jsonValue["firstName"].string else { throw JSONConvertError.missingField(field: "firstName") }
        guard let surname = jsonValue["surname"].string else { throw JSONConvertError.missingField(field: "surname") }
        guard let nicknames = jsonValue["nicknames"].array else { throw JSONConvertError.missingField(field: "nicknames") }
        guard let age = jsonValue["age"].int else { throw JSONConvertError.missingField(field: "age") }
        self.firstName = firstName
        self.surname = surname
        self.age = age
        self.nicknames = try nicknames.map { value -> String in
            guard let s = value.string else { throw JSONConvertError.invalidField(field: "nicknames")}
            return s
        }
    }
    
    init(firstName: String, surname: String, nicknames: [String], age: Int) {
        self.firstName = firstName
        self.surname = surname
        self.nicknames = nicknames
        self.age = age
    }
    
    func jsonValue() throws -> JSON {
        let value: JSON = [
            "firstName": firstName,
            "surname": surname,
            "age": age,
            "nicknames": JSON.array(nicknames.map{JSON.string($0)})
        ]
        return value
    }
}

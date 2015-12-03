//
//  JSONConvertible.swift
//  JSONCoreDemo
//
//  Created by Tyrone Trevorrow on 3/12/2015.
//  Copyright © 2015 Tyrone Trevorrow. All rights reserved.
//

import Foundation
import JSONCore

protocol JSONConvertible {
    init(jsonValue: JSONValue) throws
    func jsonValue() throws -> JSONValue
}

enum JSONConvertError: ErrorType {
    case MissingField(field: String)
    case InvalidField(field: String)
}

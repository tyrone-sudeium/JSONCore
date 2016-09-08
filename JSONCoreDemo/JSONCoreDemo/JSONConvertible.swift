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
    init(jsonValue: JSON) throws
    func jsonValue() throws -> JSON
}

enum JSONConvertError: Error {
    case missingField(field: String)
    case invalidField(field: String)
}

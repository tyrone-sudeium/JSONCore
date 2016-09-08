//
//  JSONCore.swift
//  JSONCore
//
//  Created by Tyrone Trevorrow on 23/10/2015.
//  Copyright © 2015 Tyrone Trevorrow. All rights reserved.
//

// JSONCore: A totally native Swift JSON engine
// Does NOT use NSJSONSerialization. In fact, does not require `import Foundation` at all!

// MARK: Public API

/// Errors raised while serializing to a JSON string
public enum JSONSerializeError: Error {
    /// Some unknown error, usually indicates something not yet implemented.
    case unknown
    /// A number not supported by the JSON spec was encounterd, like infinity or NaN.
    case invalidNumber
}

/// Any value that can be expressed in JSON has a representation in `JSON`.
public enum JSON {
    case object([String: JSON])
    case array([JSON])

    case null
    case bool(Bool)
    case string(String)
    case integer(Int64)
    case double(Double)

    /**
        Turns a nested graph of `JSON`s into a Swift `String`. This produces JSON data that
        strictly conforms to [ECMA-404](http://www.ecma-international.org/publications/files/ECMA-ST/ECMA-404.pdf).
        It can optionally pretty-print the output for debugging, but this comes with a non-negligible performance cost.
    */
    public func serialized(prettyPrint: Bool = false, lineEndings: JSONSerializer.LineEndings = .Unix) throws -> String {
        return try JSONSerializer(value: self, prettyPrint: prettyPrint, lineEndings: lineEndings).serialize()
    }

    /// Returns this enum's associated Array value iff `self == .array(_)`, `nil` otherwise.
    public var array: [JSON]? {
        guard case .array(let a) = self else { return nil }
        return a
    }

    /// Returns this enum's associated Dictionary value iff `self == .object(_), `nil` otherwise.
    public var object: [String: JSON]? {
        guard case .object(let o) = self else { return nil }
        return o
    }

    /// Returns this enum's associated String value iff `self == .string(_)`, `nil` otherwise.
    public var string: String? {
        guard case .string(let s) = self else { return nil }
        return s
    }

    /// Returns this enum's associated `Int64` value as an `Int` iff `self == .integer(_), `nil` otherwise.
    public var int: Int? {
        guard case .integer(let i) = self else { return nil }
        // TODO (ethan): what behaviour does this have when the native Int size is 32 bits?
        return Int(i)
    }

    /// Returns this enum's associated `Int64` iff `self == .integer(_)`, `nil` otherwise.
    public var int64: Int64? {
        guard case .integer(let i) = self else { return nil }
        return i
    }

    /// Returns this enum's associated Bool value iff `self == .bool(_)`, `nil` otherwise.
    public var bool: Bool? {
        guard case .bool(let b) = self else { return nil }
        return b
    }

    /// Returns this enum's associated Double value iff `self == .double(_)`, `nil` otherwise.
    public var double: Double? {
        guard case .double(let d) = self else { return nil }
        return d
    }
}

extension JSON: Equatable {}

public func ==(lhs: JSON, rhs: JSON) -> Bool {
    switch (lhs, rhs) {
    case (.null, .null): return true
    case (.bool(let l), .bool(let r)): return l == r
    case (.array(let l), .array(let r)): return l == r
    case (.string(let l), .string(let r)): return l == r
    case (.object(let l), .object(let r)): return l == r
    case (.integer(let l), .integer(let r)): return l == r
    case (.double(let l), .double(let r)): return l == r

    default: return false
    }
}

// MARK: - JSONEncodable

/// Used to declare that that a type can be represented as JSON
public protocol JSONEncodable {
    func encodedToJSON() -> JSON
}

extension JSON: JSONEncodable {
    public init(value: JSONEncodable) {
        self = value.encodedToJSON()
    }

    public func encodedToJSON() -> JSON {
        return self
    }
}

extension Bool: JSONEncodable {
    public func encodedToJSON() -> JSON {
        return .bool(self)
    }
}

extension String: JSONEncodable {
    public func encodedToJSON() -> JSON {
        return .string(self)
    }
}

//TODO (ethan): Check if other Int types can be made to conform to JSONEncodable without ambiguity.
extension Int: JSONEncodable {
    public func encodedToJSON() -> JSON {
        return .integer(Int64(self))
    }
}

extension Double: JSONEncodable {
    public func encodedToJSON() -> JSON {
        return .double(self)
    }
}

// MARK: - Literal Convertible

extension JSON: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: IntegerLiteralType) {
        let val = Int64(value)
        self = .integer(val)
    }
}

extension JSON: ExpressibleByFloatLiteral {
    public init(floatLiteral value: FloatLiteralType) {
        let val = Double(value)
        self = .double(val)
    }
}

extension JSON: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }

    public init(extendedGraphemeClusterLiteral value: String) {
        self = .string(value)
    }

    public init(unicodeScalarLiteral value: String) {
        self = .string(value)
    }
}

extension JSON: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: JSONEncodable...) {
            self = .array(elements.map({ $0.encodedToJSON() }))
    }
}

extension JSON: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, JSONEncodable)...) {
        var dict: [String: JSON] = [:]
        for (k, v) in elements {
            dict[k] = v.encodedToJSON()
        }

        self = .object(dict)
    }
}

extension JSON: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self = .null
    }
}

extension JSON: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .bool(value)
    }
}

extension JSON {
    init(string: String) throws {
        self = .null
    }
}

// MARK:- JSON Accessors

extension JSON {
    /**
        Treat this JSON as a JSON object and attempt to get or set its
        associated Dictionary values.
    */
    public subscript(key: String) -> JSON? {
        get {
            guard case .object(let o) = self else { return nil }
            return o[key]
        }

        set {
            guard case .object(var o) = self else { return }
            o[key] = newValue
            self = .object(o)
        }
    }

    /*
        Treat this JSON as a JSON array and attempt to get or set its
        associated Array values.
        This will do nothing if you attempt to set outside of bounds.
    */
    public subscript(index: Int) -> JSON? {
        get {
            guard case .array(let a) = self , a.indices ~= index else { return nil }
            return a[index]
        }

        set {
            guard case .array(var a) = self , a.indices ~= index else { return }
            switch newValue {
            case .some(let newValue):
                a[index] = newValue

            case .none:
                a.remove(at: index)
            }
            self = .array(a)
        }
    }
}

/**
    WARNING: Internal type. Used to constrain an extension on Optional
    to be sudo non Generic.
    *DO NOT USE* outside of JSONCore
*/
public protocol _JSONType {}
extension JSON: _JSONType {}

// TODO: Better support for set through these subscripts
// TODO: Check if it is viable to use JSONEncodable as the contraint and be rid of _JSONType
extension Optional where Wrapped: _JSONType {
    /// returns the `JSON` value for key iff `Wrapped == JSON.object(_)` and there is a value for the key
    public subscript(key: String) -> JSON? {
        // TODO(ethan): find a better way, should we fatalError() if it isn't `JSON`
        // Would be best if we could constrain extensions to be Non-Generic. Swift3?
        get {
            guard let o = (self as? JSON)?.object else { return nil }
            return o[key]
        }

        set {
            guard var o = (self as? JSON)?.object else { return }
            switch newValue {
            case .none: o.removeValue(forKey: key)
            case .some(let value):
                o[key] = value
                self = (JSON.object(o) as? Wrapped)
            }
        }
    }

    /// returns the JSON value at index iff `Wrapped == JSON.array(_)` and the index is within the arrays bounds
    public subscript(index: Int) -> JSON? {
        get {
            guard let a = (self as? JSON)?.array , a.indices ~= index else { return nil }
            return a[index]
        }

        set {
            guard var a = (self as? JSON)?.array else { return }
            switch newValue {
            case .none: a.remove(at: index)
            case .some(let value):
                a[index] = value
                self = (JSON.array(a) as? Wrapped)
            }

        }
    }

    /// Returns an array of `JSON` iff `Wrapped == JSON.array(_)`
    public var array: [JSON]? {
        guard let a = (self as? JSON)?.array else { return nil }
        return a
    }

    /// Returns a `JSON` object iff `Wrapped == JSON.object(_)`
    public var object: [String: JSON]? {
        guard let o = (self as? JSON)?.object else { return nil }
        return o
    }

    /// Returns a `String` iff `Wrapped == JSON.string(_)`
    public var string: String? {
        guard let s = (self as? JSON)?.string else { return nil }
        return s
    }

    /// Returns an `Int64` iff `Wrapped == JSON.integer(_)`
    public var int64: Int64? {
        guard let i = (self as? JSON)?.int64 else { return nil }
        return i
    }

    /// Returns an `Int` iff `Wrapped == JSON.integer(_)`
    public var int: Int? {
        guard let i = (self as? JSON)?.int else { return nil }
        return i
    }

    /// Returns a `Bool` iff `Wrapped == JSON.bool(_)`
    public var bool: Bool? {
        guard let b = (self as? JSON)?.bool else { return nil }
        return b
    }

    /// Returns a `Double` iff `Wrapped == JSON.double(_)`
    public var double: Double? {
        guard let d = (self as? JSON)?.double else { return nil }
        return d
    }
}

// MARK:- Parser
public enum JSONParseError: Error {
    /// Some unknown error, usually indicates something not yet implemented.
    case unknown
    /// Input data was either empty or contained only whitespace.
    case emptyInput
    /// Some character that violates the strict JSON grammar was found.
    case unexpectedCharacter(lineNumber: UInt, characterNumber: UInt)
    /// A JSON string was opened but never closed.
    case unterminatedString
    /// Any unicode parsing errors will result in this error. Currently unused.
    case invalidUnicode
    /// A keyword, like `null`, `true`, or `false` was expected but something else was in the input.
    case unexpectedKeyword(lineNumber: UInt, characterNumber: UInt)
    /// Encountered a JSON number that couldn't be losslessly stored in a `Double` or `Int64`.
    /// Usually the number is too large or too small.
    case invalidNumber(lineNumber: UInt, characterNumber: UInt)
    /// End of file reached, not always an actual error.
    case endOfFile
}

extension JSONParseError: CustomStringConvertible {
    /// Returns a `String` version of the error which can be logged.
    /// Not currently localized.
    public var description: String {
        switch self {
        case .unknown:
            return "Unknown error"
        case .emptyInput:
            return "Empty input"
        case .unexpectedCharacter(let lineNumber, let charNum):
            return "Unexpected character at \(lineNumber):\(charNum)"
        case .unterminatedString:
            return "Unterminated string"
        case .invalidUnicode:
            return "Invalid unicode"
        case .unexpectedKeyword(let lineNumber, let characterNumber):
            return "Unexpected keyword at \(lineNumber):\(characterNumber)"
        case .endOfFile:
            return "Unexpected end of file"
        case .invalidNumber:
            return "Invalid number"
        }
    }
}

// MARK:- Parser

// The structure of this parser is inspired by the great (and slightly insane) NextiveJson parser:
// https://github.com/nextive/NextiveJson

/**
Turns a String represented as a collection of Unicode scalars into a nested graph
of `JSON`s. This is a strict parser implementing [ECMA-404](http://www.ecma-international.org/publications/files/ECMA-ST/ECMA-404.pdf).
Being strict, it doesn't support common JSON extensions such as comments.
*/
open class JSONParser {
    /**
    A shortcut for creating a `JSONParser` and having it parse the given data.
    This is a blocking operation, and will block the calling thread until parsing
    finishes or throws an error.
    - Parameter scalars: The Unicode scalars representing the input JSON data.
    - Returns: The root `JSON` node from the input data.
    - Throws: A `JSONParseError` if something failed during parsing.
    */
    open class func parse(scalars: String.UnicodeScalarView) throws -> JSON {
        let parser = JSONParser(scalars: scalars)
        return try parser.parse()
    }

    /**
    A shortcut for creating a `JSONParser` and having it parse the given `String`.
    This is a blocking operation, and will block the calling thread until parsing
    finishes or throws an error.
    - Parameter string: The `String` of the input JSON.
    - Returns: The root `JSON` node from the input data.
    - Throws: A `JSONParseError` if something failed during parsing.
    */
    open class func parse(string: String) throws -> JSON {
        let parser = JSONParser(scalars: string.unicodeScalars)
        return try parser.parse()
    }

    /**
    Designated initializer for `JSONParser`, which requires an input Unicode scalar
    collection.
    - Parameter scalars: The Unicode scalars representing the input JSON data.
    */
    public init(scalars: String.UnicodeScalarView) {
        generator = scalars.makeIterator()
        self.data = scalars
    }

    /**
    Starts parsing the data. This is a blocking operation, and will block the
    calling thread until parsing finishes or throws an error.
    - Returns: The root `JSON` node from the input data.
    - Throws: A `JSONParseError` if something failed during parsing.
    */
    open func parse() throws -> JSON {
        do {
            try nextScalar()
            let value = try nextValue()
            do {
                try nextScalar()
                let v = scalar.value
                if v == 0x0009 || v == 0x000A || v == 0x000D || v == 0x0020 {
                    // Skip to EOF or the next token
                    try skipToNextToken()
                    // If we get this far some token was found ...
                    throw JSONParseError.unexpectedCharacter(lineNumber: lineNumber, characterNumber: charNumber)
                } else {
                    // There's some weird character at the end of the file...
                    throw JSONParseError.unexpectedCharacter(lineNumber: lineNumber, characterNumber: charNumber)
                }
            } catch JSONParseError.endOfFile {
                return value
            }
        } catch JSONParseError.endOfFile {
            throw JSONParseError.emptyInput
        }
    }

    // MARK: - Internals: Properties

    var generator: String.UnicodeScalarView.Iterator
    let data: String.UnicodeScalarView
    var scalar: UnicodeScalar!
    var lineNumber: UInt = 0
    var charNumber: UInt = 0

    var crlfHack = false

}

// MARK: JSONParser Internals
extension JSONParser {
    // MARK: - Enumerating the scalar collection
    func nextScalar() throws {
        if let sc = generator.next() {
            scalar = sc
            charNumber = charNumber + 1
            if crlfHack == true && sc != lineFeed {
                crlfHack = false
            }
        } else {
            throw JSONParseError.endOfFile
        }
    }

    func skipToNextToken() throws {
        var v = scalar.value
        if v != 0x0009 && v != 0x000A && v != 0x000D && v != 0x0020 {
            throw JSONParseError.unexpectedCharacter(lineNumber: lineNumber, characterNumber: charNumber)
        }

        while v == 0x0009 || v == 0x000A || v == 0x000D || v == 0x0020 {
            if scalar == carriageReturn || scalar == lineFeed {
                if crlfHack == true && scalar == lineFeed {
                    crlfHack = false
                    charNumber = 0
                } else {
                    if (scalar == carriageReturn) {
                        crlfHack = true
                    }
                    lineNumber = lineNumber + 1
                    charNumber = 0
                }
            }
            try nextScalar()
            v = scalar.value
        }
    }

    func nextScalars(count: UInt) throws -> [UnicodeScalar] {
        var values = [UnicodeScalar]()
        values.reserveCapacity(Int(count))
        for _ in 0..<count {
            try nextScalar()
            values.append(scalar)
        }
        return values
    }

    // MARK: - Parse loop
    func nextValue() throws -> JSON {
        let v = scalar.value
        if v == 0x0009 || v == 0x000A || v == 0x000D || v == 0x0020 {
            try skipToNextToken()
        }
        switch scalar {
        case leftCurlyBracket:
            return try nextObject()
        case leftSquareBracket:
            return try nextArray()
        case quotationMark:
            return try nextString()
        case trueToken[0], falseToken[0]:
            return try nextBool()
        case nullToken[0]:
            return try nextNull()
        case "0".unicodeScalars.first!..."9".unicodeScalars.first!,negativeScalar,decimalScalar:
            return try nextNumber()
        default:
            throw JSONParseError.unexpectedCharacter(lineNumber: lineNumber, characterNumber: charNumber)
        }
    }

    // MARK: - Parse a specific, expected type
    func nextObject() throws -> JSON {
        if scalar != leftCurlyBracket {
            throw JSONParseError.unexpectedCharacter(lineNumber: lineNumber, characterNumber: charNumber)
        }
        var dictBuilder = [String: JSON]()
        try nextScalar()
        if scalar == rightCurlyBracket {
            // Empty object
            return JSON.object(dictBuilder)
        }
        outerLoop: repeat {
            var v = scalar.value
            if v == 0x0009 || v == 0x000A || v == 0x000D || v == 0x0020 {
                try skipToNextToken()
            }
            let string = try nextString()
            try nextScalar() // Skip the quotation character
            v = scalar.value
            if v == 0x0009 || v == 0x000A || v == 0x000D || v == 0x0020 {
                try skipToNextToken()
            }
            if scalar != colon {
                throw JSONParseError.unexpectedCharacter(lineNumber: lineNumber, characterNumber: charNumber)
            }
            try nextScalar() // Skip the ':'
            let value = try nextValue()
            switch value {
            // Skip the closing character for all values except number, which doesn't have one
            case .integer, .double:
                break
            default:
                try nextScalar()
            }
            v = scalar.value
            if v == 0x0009 || v == 0x000A || v == 0x000D || v == 0x0020 {
                try skipToNextToken()
            }
            guard case .string(let key) = string else { throw JSONParseError.unknown }
            //let key = string.string! // We're pretty confident it's a string since we called nextString() above
            dictBuilder[key] = value
            switch scalar {
            case rightCurlyBracket:
                break outerLoop
            case comma:
                try nextScalar()
            default:
                throw JSONParseError.unexpectedCharacter(lineNumber: lineNumber, characterNumber: charNumber)
            }

        } while true
        return JSON.object(dictBuilder)
    }

    func nextArray() throws -> JSON {
        if scalar != leftSquareBracket {
            throw JSONParseError.unexpectedCharacter(lineNumber: lineNumber, characterNumber: charNumber)
        }
        var arrBuilder = [JSON]()
        try nextScalar()
        let v = scalar.value
        if v == 0x0009 || v == 0x000A || v == 0x000D || v == 0x0020 {
            try skipToNextToken()
        }
        if scalar == rightSquareBracket {
            // Empty array
            return JSON.array(arrBuilder)
        }
        outerLoop: repeat {
            let value = try nextValue()
            arrBuilder.append(value)
            switch value {
            // Skip the closing character for all values except number, which doesn't have one
            case .integer, .double:
                break
            default:
                try nextScalar()
            }
            let v = scalar.value
            if v == 0x0009 || v == 0x000A || v == 0x000D || v == 0x0020 {
                try skipToNextToken()
            }
            switch scalar {
            case rightSquareBracket:
                break outerLoop
            case comma:
                try nextScalar()
            default:
                throw JSONParseError.unexpectedCharacter(lineNumber: lineNumber, characterNumber: charNumber)
            }
        } while true

        return JSON.array(arrBuilder)
    }

    func nextString() throws -> JSON {
        if scalar != quotationMark {
            throw JSONParseError.unexpectedCharacter(lineNumber: lineNumber, characterNumber: charNumber)
        }
        try nextScalar() // Skip pas the quotation character
        var strBuilder = ""
        var escaping = false
        outerLoop: repeat {
            // First we should deal with the escape character and the terminating quote
            switch scalar {
            case reverseSolidus:
                // Escape character
                if escaping {
                    // Escaping the escape char
                    strBuilder.unicodeScalars.append(reverseSolidus)
                }
                escaping = !escaping
                try nextScalar()
            case quotationMark:
                if escaping {
                    strBuilder.unicodeScalars.append(quotationMark)
                    escaping = false
                    try nextScalar()
                } else {
                    break outerLoop
                }
            default:
                // Now the rest
                if escaping {
                    // Handle all the different escape characters
                    if let s = escapeMap[scalar] {
                        strBuilder.unicodeScalars.append(s)
                        try nextScalar()
                    } else if scalar == "u".unicodeScalars.first! {
                        let escapedUnicodeValue = try nextUnicodeEscape()
                        guard let escapedUnicodeScalar = UnicodeScalar(escapedUnicodeValue) else {
                            throw JSONParseError.invalidUnicode
                        }
                        strBuilder.unicodeScalars.append(escapedUnicodeScalar)
                        try nextScalar()
                    }
                    escaping = false
                } else {
                    // Simple append
                    strBuilder.append(String(scalar))
                    try nextScalar()
                }
            }
        } while true
        return JSON.string(strBuilder)
    }

    func nextUnicodeEscape() throws -> UInt32 {
        if scalar != "u".unicodeScalars.first! {
            throw JSONParseError.unexpectedCharacter(lineNumber: lineNumber, characterNumber: charNumber)
        }
        var readScalar = UInt32(0)
        for _ in 0...3 {
            readScalar = readScalar * 16
            try nextScalar()
            if ("0".unicodeScalars.first!..."9".unicodeScalars.first!).contains(scalar) {
                readScalar = readScalar + UInt32(scalar.value - "0".unicodeScalars.first!.value)
            } else if ("a".unicodeScalars.first!..."f".unicodeScalars.first!).contains(scalar) {
                let aScalarVal = "a".unicodeScalars.first!.value
                let hexVal = scalar.value - aScalarVal
                let hexScalarVal = hexVal + 10
                readScalar = readScalar + hexScalarVal
            } else if ("A".unicodeScalars.first!..."F".unicodeScalars.first!).contains(scalar) {
                let aScalarVal = "A".unicodeScalars.first!.value
                let hexVal = scalar.value - aScalarVal
                let hexScalarVal = hexVal + 10
                readScalar = readScalar + hexScalarVal
            } else {
                throw JSONParseError.unexpectedCharacter(lineNumber: lineNumber, characterNumber: charNumber)
            }
        }
        if readScalar >= 0xD800 && readScalar <= 0xDBFF {
            // UTF-16 surrogate pair
            // The next character MUST be the other half of the surrogate pair
            // Otherwise it's a unicode error
            do {
                try nextScalar()
                if scalar != reverseSolidus {
                    throw JSONParseError.invalidUnicode
                }
                try nextScalar()
                let secondScalar = try nextUnicodeEscape()
                if secondScalar < 0xDC00 || secondScalar > 0xDFFF {
                    throw JSONParseError.invalidUnicode
                }
                let actualScalar = ((readScalar - 0xD800) * 0x400) + ((secondScalar - 0xDC00) + 0x10000)
                return actualScalar
            } catch JSONParseError.unexpectedCharacter {
                throw JSONParseError.invalidUnicode
            }
        }
        return readScalar
    }

    func nextNumber() throws -> JSON {
        var isNegative = false
        var hasDecimal = false
        var hasDigits = false
        var hasExponent = false
        var positiveExponent = false
        var exponent = 0
        var integer: UInt64 = 0
        var decimal: Int64 = 0
        var divisor: Double = 10
        let lineNumAtStart = lineNumber
        let charNumAtStart = charNumber

        do {
            outerLoop: repeat {
                switch scalar {
                case "0".unicodeScalars.first!..."9".unicodeScalars.first!:
                    hasDigits = true
                    if hasDecimal {
                        decimal *= 10
                        decimal += Int64(scalar.value - zeroScalar.value)
                        divisor *= 10
                    } else {
                        integer *= 10
                        integer += UInt64(scalar.value - zeroScalar.value)
                    }
                    try nextScalar()
                case negativeScalar:
                    if hasDigits || hasDecimal || hasDigits || isNegative {
                        throw JSONParseError.unexpectedCharacter(lineNumber: lineNumber, characterNumber: charNumber)
                    } else {
                        isNegative = true
                    }
                    try nextScalar()
                case decimalScalar:
                    if hasDecimal {
                        throw JSONParseError.unexpectedCharacter(lineNumber: lineNumber, characterNumber: charNumber)
                    } else {
                        hasDecimal = true
                    }
                    try nextScalar()
                case "e".unicodeScalars.first!,"E".unicodeScalars.first!:
                    if hasExponent {
                        throw JSONParseError.unexpectedCharacter(lineNumber: lineNumber, characterNumber: charNumber)
                    } else {
                        hasExponent = true
                    }
                    try nextScalar()
                    switch scalar {
                    case "0".unicodeScalars.first!..."9".unicodeScalars.first!:
                        positiveExponent = true
                    case plusScalar:
                        positiveExponent = true
                        try nextScalar()
                    case negativeScalar:
                        positiveExponent = false
                        try nextScalar()
                    default:
                        throw JSONParseError.unexpectedCharacter(lineNumber: lineNumber, characterNumber: charNumber)
                    }
                    exponentLoop: repeat {
                        if scalar.value >= zeroScalar.value && scalar.value <= "9".unicodeScalars.first!.value {
                            exponent *= 10
                            exponent += Int(scalar.value - zeroScalar.value)
                            try nextScalar()
                        } else {
                            break exponentLoop
                        }
                    } while true
                default:
                    break outerLoop
                }
            } while true
        } catch JSONParseError.endOfFile {
            // This is fine
        }

        if !hasDigits {
            throw JSONParseError.unexpectedCharacter(lineNumber: lineNumber, characterNumber: charNumber)
        }

        let sign = isNegative ? -1: 1
        if hasDecimal || hasExponent {
            divisor /= 10
            var number = Double(sign) * (Double(integer) + (Double(decimal) / divisor))
            if hasExponent {
                if positiveExponent {
                    for _ in 1...exponent {
                        number *= Double(10)
                    }
                } else {
                    for _ in 1...exponent {
                        number /= Double(10)
                    }
                }
            }
            return JSON.double(number)
        } else {
            var number: Int64
            if isNegative {
                if integer > UInt64(Int64.max) + 1 {
                    throw JSONParseError.invalidNumber(lineNumber: lineNumAtStart, characterNumber: charNumAtStart)
                } else if integer == UInt64(Int64.max) + 1 {
                    number = Int64.min
                } else {
                    number = Int64(integer) * -1
                }
            } else {
                if integer > UInt64(Int64.max) {
                    throw JSONParseError.invalidNumber(lineNumber: lineNumAtStart, characterNumber: charNumAtStart)
                } else {
                    number = Int64(integer)
                }
            }
            return JSON.integer(Int64(number))
        }
    }

    func nextBool() throws -> JSON {
        var expectedWord: [UnicodeScalar]
        var expectedBool: Bool
        let lineNumAtStart = lineNumber
        let charNumAtStart = charNumber
        if scalar == trueToken[0] {
            expectedWord = trueToken
            expectedBool = true
        } else if scalar == falseToken[0] {
            expectedWord = falseToken
            expectedBool = false
        } else {
            throw JSONParseError.unexpectedCharacter(lineNumber: lineNumber, characterNumber: charNumber)
        }
        do {
            let word = try [scalar] + nextScalars(count: UInt(expectedWord.count - 1))
            if word != expectedWord {
                throw JSONParseError.unexpectedKeyword(lineNumber: lineNumAtStart, characterNumber: charNumAtStart)
            }
        } catch JSONParseError.endOfFile {
            throw JSONParseError.unexpectedKeyword(lineNumber: lineNumAtStart, characterNumber: charNumAtStart)
        }
        return JSON.bool(expectedBool)
    }

    func nextNull() throws -> JSON {
        let word = try [scalar] + nextScalars(count: 3)
        if word != nullToken {
            throw JSONParseError.unexpectedKeyword(lineNumber: lineNumber, characterNumber: charNumber-4)
        }
        return JSON.null
    }
}

// MARK: - JSONSerializer

/**
    Turns a nested graph of `JSON`s into a Swift `String`. This produces JSON data that
    strictly conforms to [ECMA-404](http://www.ecma-international.org/publications/files/ECMA-ST/ECMA-404.pdf).
    It can optionally pretty-print the output for debugging, but this comes with a non-negligible performance cost.
*/
open class JSONSerializer {

    /// What line endings should the pretty printer use
    public enum LineEndings: String {
        /// Unix (i.e Linux, Darwin) line endings: line feed
        case Unix = "\n"
        /// Windows line endings: carriage return + line feed
        case Windows = "\r\n"
    }
    /// Whether this serializer will pretty print output or not.
    open let prettyPrint: Bool

    /// What line endings should the pretty printer use
    open let lineEndings: LineEndings

    /**
     Designated initializer for `JSONSerializer`, which requires an input `JSONValue`.
     - Parameter value: The `JSONValue` to convert to a `String`.
     - Parameter prettyPrint: Whether to print superfluous newlines and spaces to
     make the output easier to read. Has a non-negligible performance cost. Defaults
     to `false`.
     */
    public init(value: JSON, prettyPrint: Bool = false, lineEndings: LineEndings = .Unix) {
        self.prettyPrint = prettyPrint
        self.rootValue = value
        self.lineEndings = lineEndings
    }

    /**
     Shortcut for creating a `JSONSerializer` and having it serialize the given
     value.
     - Parameter v: The `JSONValue` to convert to a `String`.
     - Parameter prettyPrint: Whether to print superfluous newlines and spaces to
     make the output easier to read. Has a non-negligible performance cost. Defaults
     to `false`.
     - Returns: The serialized value as a `String`.
     - Throws: A `JSONSerializeError` if something failed during serialization.
     */
    open class func serialize(value: JSON, prettyPrint: Bool = false) throws -> String {
        let serializer = JSONSerializer(value: value, prettyPrint: prettyPrint)
        return try serializer.serialize()
    }

    /**
     Serializes the value passed during initialization.
     - Returns: The serialized value as a `String`.
     - Throws: A `JSONSerializeError` if something failed during serialization.
     */
    open func serialize() throws -> String {
        try serialize(value: rootValue)
        return output
    }

    // MARK: Internals: Properties
    let rootValue: JSON
    var output: String = ""
}

// MARK: JSONSerializer Internals
extension JSONSerializer {

    func serialize(value: JSON, indentLevel: Int = 0) throws {
        switch value {
        case .double(let d):
            try serialize(double: d)
        case .integer(let i):
            serialize(int: i)
        case .null:
            serializeNull()
        case .string(let s):
            serialize(string: s)
        case .object(let obj):
            try serialize(object: obj, indentLevel: indentLevel)
        case .bool(let b):
            serialize(bool: b)
        case .array(let a):
            try serialize(array: a, indentLevel: indentLevel)
        }
    }

    func serialize(object: [String : JSON], indentLevel: Int = 0) throws {
        output.append("{")
        serializeNewline()
        var i = 0
        for (key, value) in object {
            serializeSpaces(indentLevel: indentLevel + 1)
            serialize(string: key)
            output.append(":")
            if prettyPrint {
                output.append(" ")
            }
            try serialize(value: value, indentLevel: indentLevel + 1)
            i += 1
            if i != object.count {
                output.append(",")

            }
            serializeNewline()
        }
        serializeSpaces(indentLevel: indentLevel)
        output.append("}")
    }

    func serialize(array: [JSON], indentLevel: Int = 0) throws {
        output.append("[")
        serializeNewline()
        var i = 0
        for val in array {
            serializeSpaces(indentLevel: indentLevel + 1)
            try serialize(value: val, indentLevel: indentLevel + 1)
            i += 1
            if i != array.count {
                output.append(",")
            }
            serializeNewline()
        }
        serializeSpaces(indentLevel: indentLevel)
        output.append("]")
    }

    func serialize(string: String) {
        output.append("\"")
        var generator = string.unicodeScalars.makeIterator()
        while let scalar = generator.next() {
            switch scalar.value {
            case (solidus.value):
                fallthrough
            case 0x0000...0x001F:
                output.append("\\")
                switch scalar {
                case tabCharacter:
                    output.append("t")
                case carriageReturn:
                    output.append("r")
                case lineFeed:
                    output.append("n")
                case quotationMark:
                    output.append("\"")
                case backspace:
                    output.append("b")
                case solidus:
                    output.append("/")
                default:
                    output.append("u")
                    output.append(hexStrings[(Int(scalar.value) & 0xF000) >> 12])
                    output.append(hexStrings[(Int(scalar.value) & 0x0F00) >> 8])
                    output.append(hexStrings[(Int(scalar.value) & 0x00F0) >> 4])
                    output.append(hexStrings[(Int(scalar.value) & 0x000F) >> 0])
                }
            default:
                output.unicodeScalars.append(scalar)
            }
        }
        output.append("\"")
    }

    func serialize(double: Double) throws {
        guard double.isFinite else { throw JSONSerializeError.invalidNumber }
        // TODO: Is CustomStringConvertible for number types affected by locale?
        // TODO: Is CustomStringConvertible for Double fast?
        output.append(double.description)
    }

    func serialize(int: Int64) {
        // TODO: Is CustomStringConvertible for number types affected by locale?
        output.append(int.description)
    }

    func serialize(bool: Bool) {
        switch bool {
        case true:
            output.append("true")
        case false:
            output.append("false")
        }
    }

    func serializeNull() {
        output.append("null")
    }

    @inline(__always)
    fileprivate final func serializeNewline() {
        if prettyPrint {
            output.append(lineEndings.rawValue)
        }
    }

    @inline(__always)
    fileprivate final func serializeSpaces(indentLevel: Int = 0) {
        if prettyPrint {
            for _ in 0..<indentLevel {
                output.append("  ")
            }
        }
    }
}

// MARK:- Unicode Scalars

private let leftSquareBracket = UnicodeScalar(0x005b)!
private let leftCurlyBracket = UnicodeScalar(0x007b)!
private let rightSquareBracket = UnicodeScalar(0x005d)!
private let rightCurlyBracket = UnicodeScalar(0x007d)!
private let colon = UnicodeScalar(0x003A)!
private let comma = UnicodeScalar(0x002C)!
private let zeroScalar = "0".unicodeScalars.first!
private let negativeScalar = "-".unicodeScalars.first!
private let plusScalar = "+".unicodeScalars.first!
private let decimalScalar = ".".unicodeScalars.first!
private let quotationMark = UnicodeScalar(0x0022)!
private let carriageReturn = UnicodeScalar(0x000D)!
private let lineFeed = UnicodeScalar(0x000A)!

// String escapes
private let reverseSolidus = UnicodeScalar(0x005C)!
private let solidus = UnicodeScalar(0x002F)!
private let backspace = UnicodeScalar(0x0008)!
private let formFeed = UnicodeScalar(0x000C)!
private let tabCharacter = UnicodeScalar(0x0009)!

private let trueToken = [UnicodeScalar]("true".unicodeScalars)
private let falseToken = [UnicodeScalar]("false".unicodeScalars)
private let nullToken = [UnicodeScalar]("null".unicodeScalars)

private let escapeMap = [
    "/".unicodeScalars.first!: solidus,
    "b".unicodeScalars.first!: backspace,
    "f".unicodeScalars.first!: formFeed,
    "n".unicodeScalars.first!: lineFeed,
    "r".unicodeScalars.first!: carriageReturn,
    "t".unicodeScalars.first!: tabCharacter
]

private let hexStrings = [
    "0",
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
    "9",
    "a",
    "b",
    "c",
    "d",
    "e",
    "f"
]

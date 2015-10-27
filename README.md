# JSON Core
JSON Core is a JSON parser written using only core Swift. This means it has no
dependencies on Foundation, UIKit, AppKit or even Darwin. This is a true parser,
it doesn't use `NSJSONSerialization` at all, nor does it call out to any C
JSON library.

## Why?

### Portability
At WWDC 2015 Apple announced their intention to release an open source version
of Swift. When this happens it is very likely that what they'll release is the
code for the `swiftc` compiler as well as the source code for `libswiftCore`,
which contains the basic Swift types such as `Array` and `Dictionary`. At this
stage no one knows if they'll release a version of Foundation. Even though
CoreFoundation is open source, it's not exactly portable, and it may not bridge
as seamlessly to Swift as the Objective-C Foundation does.

JSON transformation is a pretty essential capability for any language or
platform, and it'll likely be missing from the cross-platform version of Swift
at launch. With any luck at launch JSON Core will work with only minor
modifications on the open source Swift compiler.

### Performance
The Swift - Objective-C bridge is very efficient for the most part. However,
when dealing with potentially millions of object allocations, passing them back
and forth through the bridge is extremely costly. This is completely unnecessary
busywork for the CPU and is just a side effect of the fact that the standard
JSON engine for Swift today is an Objective-C class, `NSJSONSerialization`,
which returns Objective-C objects.

JSON Core works only on native Swift types, `Array`, `Dictionary`, `Int64`,
`Double`, and `Bool`, which means there's no bridging required. It's still a
long way off being as efficient as `NSJSONSerialization` in Objective-C only
mode, but it's already considerably faster than `NSJSONSerialization` when used
with Swift code.

Here's a chart showing the performance characteristics of JSON Core when parsing
an extremely large JSON file from disk. The source JSON file is generated when
running the unit test and contains an array of one million JSON objects. The
file is approximately 212MB.

![Chart](/Images/Chart.png)

Over time I'd like to improve this but at the moment I'm limited mostly by the
performance of `Dictionary`. It's extremely costly to build up a `Dictionary` by
creating an empty one and then setting values and keys manually, but as of
Swift 2.1, there's no other way to create a `Dictionary` dynamically. In
Foundation / CoreFoundation it's possible to very quickly create an
`NSDictionary` using a C array of values and keys. Unless I write my own data
structure to represent JSON objects, which means giving up the advantages of
simply returning a Swift `Dictionary` to the caller, I'm probably not going to
get a huge amount more performance. If `libswiftCore` goes open source it should
give further insight into the performance characteristics of `Dictionary`, too.

Be aware that if the string you pass in to `JSONParser.parseData` was bridged
using an `NSString` constructor, there'll be serious performance ramifications.
You should be aware of what's constructing your raw JSON data object and how
it gets initialised. You'll get an almost 2x speed boost by sticking to `String`
over `NSString`.

## Usage
```Swift
let json = "{\"test\": 1}"
do {
    let value = try JSONParser.parseData(json.unicodeScalars)
    // value is a JSONValue enum, which for our JSON should be
    // an Object/Dictionary
    guard let test = value.object?["test"]?.int else { return }
    print("test is \(test)")
} catch let err {
    if let printableError = err as? CustomStringConvertible {
        print("JSON parse error: \(printableError)")
    }
}
```

## Installation
I'm not on Carthage or CocoaPods (yet!), however, JSON Core is just a single
Swift file with zero dependencies, so feel free to make this repo a submodule
and just drop the `JSONCore.swift` file into your project directly. I will add
support for Carthage and CocoaPods when I'm happy JSON Core is stable enough for
production use.

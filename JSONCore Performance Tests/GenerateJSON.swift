#!/usr/bin/env xcrun swift
//
//  GenerateJSON.swift
//  JSONCore
//
//  Created by Tyrone Trevorrow on 23/03/2016.
//  Copyright © 2016 Tyrone Trevorrow. All rights reserved.
//

// It's easier to depend on Foundation for this than to try to self-host!
import Foundation

let numElements = 1000000
let arc4random_max = 0x100000000
var arr = [NSDictionary]()

func randomNumber() -> Double {
    return Double(arc4random()) / Double(arc4random_max)
}

func randomName() -> String {
    var str = ""
    let chars = Array("abcdefghijklmnopqrstuvwxyz".characters)
    for _ in 0...5 {
        let char = chars[Int(arc4random_uniform(UInt32(chars.count)))]
        str.append(char)
    }
    str.append(" ")
    str.append(arc4random_uniform(10000).description)
    return str
}

for _ in 0..<numElements {
    arr.append([
        "x": randomNumber(),
        "y": randomNumber(),
        "z": randomNumber(),
        "name": randomName(),
        "opts": [
            "1": [1, true]
        ]
    ] as NSDictionary)
}
let obj = ["coordinates": arr, "info": "some info"]

let data = try! JSONSerialization.data(withJSONObject: obj as NSDictionary, options: [.prettyPrinted])
try! data.write(to: URL(fileURLWithPath: "1.json"), options: [.dataWritingAtomic])

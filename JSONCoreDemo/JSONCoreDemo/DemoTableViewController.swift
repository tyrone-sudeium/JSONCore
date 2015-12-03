//
//  DemoTableViewController.swift
//  JSONCoreDemo
//
//  Created by Tyrone Trevorrow on 3/12/2015.
//  Copyright © 2015 Tyrone Trevorrow. All rights reserved.
//

import UIKit
import JSONCore

class DemoTableViewController: UITableViewController {
    var currentEditor: JSONEditorViewController?
    var jsonString: String?
    
    override func viewDidLoad() {
        let people = [
            Person(firstName: "John", surname: "Citizen", nicknames: ["Q"], age: 31),
            Person(firstName: "Jane", surname: "Citizen", nicknames: [], age: 31),
            Person(firstName: "Groot", surname: "Groot", nicknames: ["Groot"], age: 0),
        ]
        let peopleValue = JSONValue.JSONArray(people.map { try! $0.jsonValue() })
        jsonString = try! JSONSerializer.serializeValue(peopleValue, prettyPrint: true)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let editor = currentEditor {
            jsonString = editor.string
        }
    }
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segue.identifier {
        case .Some("EditorSegue"):
            currentEditor = segue.destinationViewController as? JSONEditorViewController
            if let editor = currentEditor {
                editor.string = jsonString
            }
        case .Some("ParseSegue"):
            guard let peopleVC = segue.destinationViewController as? PeopleTableViewController else { return }
            peopleVC.jsonString = jsonString
        default:
            break
        }
    }
}

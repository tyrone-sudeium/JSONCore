//
//  PeopleTableViewController.swift
//  JSONCoreDemo
//
//  Created by Tyrone Trevorrow on 3/12/2015.
//  Copyright © 2015 Tyrone Trevorrow. All rights reserved.
//

import UIKit
import JSONCore

enum ParseResult {
    case People([Person])
    case ConvertError(JSONConvertError)
    case ParseError(JSONParseError)
    case NotParsed
}

class PeopleTableViewController: UITableViewController {
    
    var result = ParseResult.NotParsed
    var jsonString: String?
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        result = ParseResult.NotParsed
        tableView.reloadData()
        
        guard let json = jsonString else { return }
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
            do {
                let value = try JSONParser.parseData(json.unicodeScalars)
                guard let peopleValues = value.array else { throw JSONConvertError.InvalidField(field: "root") }
                let people = try peopleValues.map { try Person.init(jsonValue: $0) }
                self.result = ParseResult.People(people)
            } catch let error {
                if let convertErr = error as? JSONConvertError {
                    self.result = ParseResult.ConvertError(convertErr)
                } else if let parseErr = error as? JSONParseError {
                    self.result = ParseResult.ParseError(parseErr)
                }
            }
            dispatch_async(dispatch_get_main_queue()) {
                self.tableView.reloadData()
            }
        }
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        switch result {
        case .People(let people):
            return people.count
        case .NotParsed:
            return 0
        default:
            return 1
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch result {
        case .People:
            return 4
        case .NotParsed:
            return 0
        default:
            return 1
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let id = self.tableView(tableView, cellIdentifierForRowAtIndexPath: indexPath)
        let cell = tableView.dequeueReusableCellWithIdentifier(id, forIndexPath: indexPath)
        switch result {
        case .People(let people):
            let person = people[indexPath.section]
            configurePersonCell(cell, forRowAtIndexPath: indexPath, person: person)
        case .ConvertError(let error):
            configureConvertErrorCell(cell, forRowAtIndexPath: indexPath, error: error)
        case .ParseError(let error):
            configureParseErrorCell(cell, forRowAtIndexPath: indexPath, error: error)
        default:
            break
        }
        return cell
    }
    
    func tableView(tableView: UITableView, cellIdentifierForRowAtIndexPath: NSIndexPath) -> String {
        switch result {
        case .People:
            return "PersonInfoCell"
        default:
            return "ErrorCell"
        }
    }
    
    func configurePersonCell(cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath, person: Person) {
        let values = [
            person.firstName,
            person.surname,
            "\(person.age)",
            (person.nicknames as NSArray).componentsJoinedByString(", ")
        ]
        let titles = [
            "First Name",
            "Surname",
            "Age",
            "Nicknames"
        ]
        
        if indexPath.row < titles.count {
            cell.textLabel?.text = titles[indexPath.row]
            cell.detailTextLabel?.text = values[indexPath.row]
        }
    }
    
    func configureConvertErrorCell(cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath, error: JSONConvertError) {
        switch error {
        case .InvalidField(let field):
            cell.textLabel?.text = "Invalid field: \(field)"
        case .MissingField(let field):
            cell.textLabel?.text = "Missing field: \(field)"
        }
    }
    
    func configureParseErrorCell(cell: UITableViewCell, forRowAtIndexPath: NSIndexPath, error: JSONParseError) {
        cell.textLabel?.text = error.description
    }
    
}

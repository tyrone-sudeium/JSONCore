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
    case people([Person])
    case convertError(JSONConvertError)
    case parseError(JSONParseError)
    case notParsed
}

class PeopleTableViewController: UITableViewController {
    
    var result = ParseResult.notParsed
    var jsonString: String?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        result = ParseResult.notParsed
        tableView.reloadData()
        
        guard let json = jsonString else { return }
        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
            do {
                let value = try JSONParser.parse(scalars: json.unicodeScalars)
                guard let peopleValues = value.array else { throw JSONConvertError.invalidField(field: "root") }
                let people = try peopleValues.map { try Person.init(jsonValue: $0) }
                self.result = ParseResult.people(people)
            } catch let error {
                if let convertErr = error as? JSONConvertError {
                    self.result = ParseResult.convertError(convertErr)
                } else if let parseErr = error as? JSONParseError {
                    self.result = ParseResult.parseError(parseErr)
                }
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        switch result {
        case .people(let people):
            return people.count
        case .notParsed:
            return 0
        default:
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch result {
        case .people:
            return 4
        case .notParsed:
            return 0
        default:
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let id = self.tableView(tableView, cellIdentifierForRowAtIndexPath: indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: id, for: indexPath)
        switch result {
        case .people(let people):
            let person = people[(indexPath as NSIndexPath).section]
            configurePersonCell(cell, forRowAtIndexPath: indexPath, person: person)
        case .convertError(let error):
            configureConvertErrorCell(cell, forRowAtIndexPath: indexPath, error: error)
        case .parseError(let error):
            configureParseErrorCell(cell, forRowAtIndexPath: indexPath, error: error)
        default:
            break
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, cellIdentifierForRowAtIndexPath: IndexPath) -> String {
        switch result {
        case .people:
            return "PersonInfoCell"
        default:
            return "ErrorCell"
        }
    }
    
    func configurePersonCell(_ cell: UITableViewCell, forRowAtIndexPath indexPath: IndexPath, person: Person) {
        let values = [
            person.firstName,
            person.surname,
            "\(person.age)",
            (person.nicknames as NSArray).componentsJoined(by: ", ")
        ]
        let titles = [
            "First Name",
            "Surname",
            "Age",
            "Nicknames"
        ]
        
        if (indexPath as NSIndexPath).row < titles.count {
            cell.textLabel?.text = titles[(indexPath as NSIndexPath).row]
            cell.detailTextLabel?.text = values[(indexPath as NSIndexPath).row]
        }
    }
    
    func configureConvertErrorCell(_ cell: UITableViewCell, forRowAtIndexPath indexPath: IndexPath, error: JSONConvertError) {
        switch error {
        case .invalidField(let field):
            cell.textLabel?.text = "Invalid field: \(field)"
        case .missingField(let field):
            cell.textLabel?.text = "Missing field: \(field)"
        }
    }
    
    func configureParseErrorCell(_ cell: UITableViewCell, forRowAtIndexPath: IndexPath, error: JSONParseError) {
        cell.textLabel?.text = error.description
    }
    
}

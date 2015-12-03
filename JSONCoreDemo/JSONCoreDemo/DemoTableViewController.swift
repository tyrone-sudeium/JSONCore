//
//  DemoTableViewController.swift
//  JSONCoreDemo
//
//  Created by Tyrone Trevorrow on 3/12/2015.
//  Copyright © 2015 Tyrone Trevorrow. All rights reserved.
//

import UIKit

class DemoTableViewController: UITableViewController {
    var currentEditor: JSONEditorViewController?
    var jsonString: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let editor = currentEditor {
            jsonString = editor.string
        }
    }
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        currentEditor = sender?.destinationViewController as? JSONEditorViewController
        if let editor = currentEditor {
            editor.string = jsonString
        }
    }
}

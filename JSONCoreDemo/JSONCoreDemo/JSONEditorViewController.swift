//
//  JSONEditorViewController.swift
//  JSONCoreDemo
//
//  Created by Tyrone Trevorrow on 2/12/2015.
//  Copyright © 2015 Tyrone Trevorrow. All rights reserved.
//

import UIKit
import JSONCore

class JSONEditorViewController: UIViewController, UITextViewDelegate {
    var string: String?
    @IBOutlet var textView: UITextView!
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        registerForKeyboardNotifications()
        
        if let inputString = string {
            self.textView.text = inputString
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
        string = textView.text
    }

    func registerForKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWasShown:", name: UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillBeHidden:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func keyboardWasShown(notification: NSNotification) {
        guard let info = notification.userInfo else { return }
        guard let kbSize = info[UIKeyboardFrameBeginUserInfoKey]?.CGRectValue?.size else { return }
        
        let contentInsets = UIEdgeInsets(top: 64.0, left: 0.0, bottom: kbSize.height, right: 0.0)
        textView.contentInset = contentInsets
        textView.scrollIndicatorInsets = contentInsets
    }
    
    func keyboardWillBeHidden(notification: NSNotification) {
        let contentInsets = UIEdgeInsets(top: 64.0, left: 0.0, bottom: 0.0, right: 0.0)
        textView.contentInset = contentInsets
        textView.scrollIndicatorInsets = contentInsets
    }
}

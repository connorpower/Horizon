//
//  ViewController.swift
//  Horizon
//
//  Created by Jürgen on 02.11.17.
//  Copyright © 2017 Semantical GmbH & Co. KG. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    var dataModel: DataModel {
        let appDelegate = (NSApp.delegate) as? AppDelegate
        return appDelegate!.dataModel
    }
    
    // ************************************
    // NSTableView data source and delegate
    // ************************************

    func numberOfRows(in tableView: NSTableView) -> Int {
        guard let identifier = tableView.identifier else {
            print("Table view is missing an identifier.")
            return 0
        }
        
        switch identifier.rawValue {
        case "Contacts":
            return dataModel.contacts.count
            
        case "Files":
            return 0
            
        default:
            print("No data for table view with id \(identifier.rawValue)")
            return 0
        }
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var result:NSTableCellView
        
        guard let columnId = tableColumn?.identifier else {
            print("Table view column is missing.")
            return nil
        }
        
        switch columnId.rawValue {
        case "Contact":
            result  = tableView.makeView(withIdentifier: columnId, owner: self) as! NSTableCellView
            result.textField?.stringValue = dataModel.contacts[row].name
            return result
            
        case "File":
            result  = tableView.makeView(withIdentifier: columnId, owner: self) as! NSTableCellView
            result.textField?.stringValue = "File"
            return result

        default:
            print("No data for column with id \(columnId.rawValue)")
            return nil
        }
    }
    
}


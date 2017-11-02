//
//  ViewController.swift
//  Horizon
//
//  Created by Jürgen on 02.11.17.
//  Copyright © 2017 Semantical GmbH & Co. KG. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    
    @IBOutlet weak var contactsTableView: NSTableView!
    @IBOutlet weak var filesTableView: NSTableView!
    
    // Constants
    let contactsTableViewId = NSUserInterfaceItemIdentifier("Contacts")
    let filesTableViewId = NSUserInterfaceItemIdentifier("Files")

    // State
    var selectedContact: Contact?
    
    // Life cycle and updating
    override func viewDidLoad() {
        super.viewDidLoad()
        updateFilesTableView()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func updateFilesTableView() {
        // Update selected contact
        let row = contactsTableView.selectedRow
        if row < 0 {
            selectedContact = nil
        }
        else if row < dataModel.contacts.count {
            selectedContact = dataModel.contacts[row]
        }

        // Update files to the selected contact
        filesTableView.reloadData()
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
        
        switch identifier {
        case contactsTableViewId:
            return dataModel.contacts.count
            
        case filesTableViewId:
            if let contact = selectedContact {
                return dataModel.files(for: contact).count
            }
            else {
                return 0
            }
            
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
            let fileName: String
            if let contact = selectedContact {
                let files = dataModel.files(for: contact)
                if row < files.count {
                    fileName = files[row].name
                }
                else {
                    print("We seem to have lost files since we last retrieved the file count.")
                    fileName = "<File is missing>"
                }
            }
            else {
                print("Don't retrieve files when there's no contact selected.")
                fileName = "<Error>"
            }

            result  = tableView.makeView(withIdentifier: columnId, owner: self) as! NSTableCellView
            result.textField?.stringValue = fileName
            return result

        default:
            print("No data for column with id \(columnId.rawValue)")
            return nil
        }
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let tableView = notification.object as! NSTableView
        if tableView.identifier == contactsTableViewId {
            updateFilesTableView()
        }
    }
}


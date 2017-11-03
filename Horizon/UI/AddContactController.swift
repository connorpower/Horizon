//
//  AddContactController.swift
//  Horizon
//
//  Created by Jürgen on 03.11.17.
//  Copyright © 2017 Semantical GmbH & Co. KG. All rights reserved.
//

import Cocoa

class AddContactController: NSViewController {
   
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    @IBOutlet weak var nameField: NSTextField!
    @IBOutlet weak var idField: NSTextField!
    
    @IBAction func cancelAction(_ sender: NSButton) {
        NSApp.stopModal()
        sender.window?.close()
    }
    
    @IBAction func saveAction(_ sender: NSButton) {
        let name = nameField.stringValue
        let remoteHash = idField.stringValue
        
        if name.isEmpty || remoteHash.isEmpty {
            NSSound.beep()
            return
        }
        
        NSApp.stopModal()
        sender.window?.close()

        dataModel.addContact(contact: Contact(name: name, remoteHash: remoteHash))
    }
    
    var dataModel: DataModel {
        let appDelegate = (NSApp.delegate) as? AppDelegate
        return appDelegate!.dataModel
    }

}

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
        let receiveListHash = idField.stringValue

        if name.isEmpty || receiveListHash.isEmpty {
            NSSound.beep()
            return
        }

        NSApp.stopModal()
        sender.window?.close()

        let contact = Contact(identifier: UUID(),
                              displayName: name,
                              sendListKey: name,
                              receiveListHash: receiveListHash)
        dataModel.addContact(contact: contact)
    }

    var dataModel: DataModel {
        let appDelegate = (NSApp.delegate) as? AppDelegate
        return appDelegate!.dataModel
    }

}

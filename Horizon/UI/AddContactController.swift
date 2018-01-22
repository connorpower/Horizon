//
//  AddContactController.swift
//  Horizon
//
//  Created by Jürgen on 03.11.17.
//  Copyright © 2017 Semantical GmbH & Co. KG. All rights reserved.
//

import Cocoa
import HorizonCore

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
        model.addContact(contact: contact)
    }

    var model: Model {
        let appDelegate = (NSApp.delegate) as? AppDelegate
        return appDelegate!.model
    }

}

//
//  AddContactController.swift
//  Horizon
//
//  Created by Jürgen on 03.11.17.
//  Copyright © 2017 Connor Power. All rights reserved.
//

import Cocoa
import HorizonCore
import PromiseKit

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
        let receiveAddress = idField.stringValue

        if name.isEmpty || receiveAddress.isEmpty {
            NSSound.beep()
            return
        }

        NSApp.stopModal()
        sender.window?.close()

        // TODO: Fix
//        let contact = Contact(identifier: UUID(),
//                              displayName: name,
//                              sendListKey: name,
//                              receiveAddress: receiveAddress)
//        model.addContact(contact: contact)
    }

    var model: Model {
        let appDelegate = (NSApp.delegate) as? AppDelegate
        return appDelegate!.model
    }

}

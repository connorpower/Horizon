//
//  ShowContactSegue.swift
//  Horizon
//
//  Created by Jürgen on 03.11.17.
//  Copyright © 2017 Semantical GmbH & Co. KG. All rights reserved.
//

import Cocoa

class ShowContactSegue: NSStoryboardSegue {
    override func perform() {
        if let windowController = self.destinationController as? NSWindowController,
            let window = windowController.window {
            NSApp.runModal(for: window)
        } else {
            super.perform()
        }
    }
}

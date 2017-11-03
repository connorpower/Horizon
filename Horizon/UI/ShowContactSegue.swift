//
//  ShowContactSegue.swift
//  Horizon
//
//  Created by Jürgen on 03.11.17.
//  Copyright © 2017 Semantical GmbH & Co. KG. All rights reserved.
//

import Cocoa

class ShowContactSegue : NSStoryboardSegue {
    override func perform() {
        let windowController = self.destinationController as! NSWindowController
        NSApp.runModal(for: windowController.window!)
    }
}

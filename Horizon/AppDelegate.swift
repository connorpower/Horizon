//
//  AppDelegate.swift
//  Horizon
//
//  Created by Jürgen on 02.11.17.
//  Copyright © 2017 Semantical GmbH & Co. KG. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let dataModel = DataModel(api: IPFSAPI())

    func applicationDidFinishLaunching(_ aNotification: Notification) {}

    func applicationWillTerminate(_ aNotification: Notification) {}

}


//
//  AppDelegate.swift
//  Horizon
//
//  Created by Jürgen on 02.11.17.
//  Copyright © 2017 Semantical GmbH & Co. KG. All rights reserved.
//

import Cocoa
import AppCenter
import AppCenterAnalytics
import AppCenterCrashes
import HorizonCore

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let model = ModelFactory().model()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        MSAppCenter.start("2cb50192-2776-44c4-b8f3-e823754633c7", withServices: [MSCrashes.self, MSAnalytics.self])
    }

    @IBAction func refreshAction(_ sender: Any) {
        model.sync()
    }
}

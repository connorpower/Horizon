//
//  Notifications.swift
//  Horizon
//
//  Created by Connor Power on 30.12.17.
//  Copyright © 2017 Connor Power. All rights reserved.
//

import Foundation

struct Notifications {

    // MARK: - Constants

    static let newDataAvailable = Notification.Name("de.horizon.notification.newDataAvailable")
    static let syncStarted = Notification.Name("de.horizon.notification.syncStarted")
    static let syncEnded = Notification.Name("de.horizon.notification.syncEnded")
    static let statusMessage = Notification.Name("de.horizon.notification.statusMessage")
    static let statusMessageKey = "StatusMessage"

    // MARK: - Static Functions

    static func broadcastStatusMessage(_ message: String) {
        NotificationCenter.default.post(name: Notifications.statusMessage, object: nil,
                                        userInfo: [Notifications.statusMessageKey: message])
    }

    static func broadcastSyncStart() {
        NotificationCenter.default.post(name: Notifications.syncStarted, object: nil)
    }

    static func broadcastSyncEnd() {
        NotificationCenter.default.post(name: Notifications.syncEnded, object: nil)
    }

    static func broadcastNewData() {
        NotificationCenter.default.post(name: Notifications.newDataAvailable, object: nil)
    }

}

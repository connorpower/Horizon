//
//  MockConfiguration.swift
//  HorizonCoreTests
//
//  Created by Connor Power on 16.02.18.
//  Copyright © 2018 Connor Power. All rights reserved.
//

import Foundation

import Foundation
import IPFSWebService
@testable import HorizonCore

struct MockConfiguration: ConfigurationProvider {

    var horizonDirectory = URL(fileURLWithPath: "/tmp/horizon-mock")

    var identity = "mock-identity"

    var path = URL(fileURLWithPath: "/tmp/horizon-mock/mock-identity")

    var daemonPIDPath = URL(fileURLWithPath: "/tmp/horizon-mock/mock-identity/PID")

    var apiPort = 5001

    var gatewayPort = 8080

    var swarmPort = 4001

    var apiBasePath = "http://127.0.0.1:5001/api/v0"

    var persistentStoreKeys = PersistentStoreKeys(contactList: "com.semantical.Horizon.horizon-mock.contactList",
                                                  keypairPrefix: "com.semantical.Horizon.horizon-mock.contact")

}

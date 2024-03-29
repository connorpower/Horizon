//
//  Configuration.swift
//  HorizonCore
//
//  Created by Connor Power on 16.02.18.
//  Copyright © 2018 Connor Power. All rights reserved.
//

import Foundation

/**
 The `Configuration` struct is central to the running of
 horizon. Horizon runs with a dedicated IPFS instance so as not
 to have it's data tampered with by the default version.
 Furthermore, horizon supports multiple identities, each of which
 may run simultaneously and independently from oneanother.
 */
public struct Configuration: ConfigurationProvider {

    // MARK: - Properties

    public let horizonDirectory: URL
    public let identity: String
    public let path: URL
    public let daemonPIDPath: URL
    public let apiPort: Int
    public let gatewayPort: Int
    public let swarmPort: Int
    public let apiBasePath: String

    public var persistentStoreKeys: PersistentStoreKeys {
        return PersistentStoreKeys(contactList: "com.semantical.Horizon.\(identity).contactList",
                                   keypairPrefix: "com.semantical.Horizon.\(identity).contact")
    }

    // MARK: - Initialization

    public init(horizonDirectory: URL, identity: String) {
        // Generate a random port between 1024 and 65535
        func randomSafePort(for identity: String, basePort: Int) -> Int {
            let MAX_PORT = 65535
            let PROTECTED_PORTS = 1024

            return (basePort.hashValue ^ identity.hashValue) % (MAX_PORT - PROTECTED_PORTS - 1) + PROTECTED_PORTS
        }

        self.horizonDirectory = horizonDirectory
        self.identity = identity
        self.path = self.horizonDirectory.appendingPathComponent(identity)
        self.daemonPIDPath = self.path.appendingPathComponent("PID")
        self.apiPort = randomSafePort(for: identity, basePort: 5001)
        self.gatewayPort = randomSafePort(for: identity, basePort: 8080)
        self.swarmPort = randomSafePort(for: identity, basePort: 4001)
        self.apiBasePath = "http://127.0.0.1:\(self.apiPort)/api/v0"
    }

}

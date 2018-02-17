//
//  ConfigurationProvider.swift
//  HorizonCore
//
//  Created by Connor Power on 16.02.18.
//  Copyright © 2018 Semantical GmbH & Co. KG. All rights reserved.
//

import Foundation

public struct PersistentStoreKeys {
    // The contact list name as stored in UserDefaults
    public let contactList: String

    // The keypair name given to an IPFS keypair with `ipfs key gen`
    public let keypairPrefix: String
}

/**
 The `ConfigurationProvider` prototocl is central to the running of
 horizon. Horizon runs with a dedicated IPFS instance so as not
 to have it's data tampered with by the default version.
 Furthermore, horizon supports multiple identities, each of which
 may run simultaneously and independently from oneanother. A
 configuration allows horizon to internally compartmentalise
 each of it's persistence, api and key related calls so that
 they pertain to only a single "identity".

 This protocol allows for easy unit testing.
 */
public protocol ConfigurationProvider {

    // MARK: - Properties

    var horizonDirectory: URL { get }
    var identity: String { get }
    var path: URL { get }
    var daemonPIDPath: URL { get }
    var apiPort: Int { get }
    var gatewayPort: Int { get }
    var swarmPort: Int { get }
    var apiBasePath: String { get }

    var persistentStoreKeys: PersistentStoreKeys { get }

}

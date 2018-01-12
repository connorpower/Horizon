//
//  Contact.swift
//  Horizon
//
//  Created by Jürgen on 02.11.17.
//  Copyright © 2017 Semantical GmbH & Co. KG. All rights reserved.
//

import Foundation

/**
 A `Contact` represents a single remote user with which files
 can be shared.
 */
struct Contact: Codable {

    /**
     The user visible name, which is displayed in the UI.
     */
    let name: String

    /**
     The name for an IPNS keypair on the local machine. Via the IPFS
     API, IPNS keypairs are manipulated using a human readable name.
     */
    let sendListKey: String

    /**
     The IPNS hash for the remote file list. This must be provided
     by the other user.
     */
    let receiveListHash: String

}

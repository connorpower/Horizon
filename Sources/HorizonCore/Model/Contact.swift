//
//  Contact.swift
//  HorizonCore
//
//  Created by Jürgen on 02.11.17.
//  Copyright © 2017 Semantical GmbH & Co. KG. All rights reserved.
//

import Foundation

// MARK: - Properties

/**
 A `SendAddress` represents an ecapsulation of both a local keypair
 name (as used by local IPFS commands) and the address to which the
 keypair relates (as given out to other contacts).
 */
public struct SendAddress: Codable {
    public let address: String
    public let keypairName: String
}

/**
 A `Contact` represents a single remote user with which files
 can be shared.
 */
public struct Contact: Codable {

    // MARK: - Properties

    /**
     A unique identifier for the contact.
     */
    public let identifier: UUID

    /**
     The user visible name, which is displayed in the UI.
     */
    public let displayName: String

    /**
     The send address a for files shared with the contact. This consists
     of a struct due to the way that the local IPNS node interacts with
     keypairs via name only.
     */
    public let sendAddress: SendAddress?

    /**
     The IPNS hash for the remote file list. This must be provided
     by the other user.
     */
    public let receiveAddress: String?

    /**
     The list of files which are to be shared with the contact.
     */
    public var sendList = FileList(hash: nil, files: [])

    /**
     The last known file list from the contact.
     */
    public var receiveList = FileList(hash: nil, files: [])

    // MARK: - Initializer

    /**
     Initializes a new contact. A newly initialized contact will have
     both empty send and receive file lists.

     - parameter identifier: An identifier for the contact. This should
       be generated by the calling function.
     - parameter displayName: he user visible name, which is displayed
       in the UI.
     - parameter sendAddress: An addreess/keypair combo which corresponds
       to an IPNS keypair on the local machine.
     - parameter receiveAddress: An IPNS hash provided by the contact,
       through which their current list of shared files can be resolved.
     */
    public init(identifier: UUID, displayName: String, sendAddress: SendAddress?, receiveAddress: String?) {
        self.identifier = identifier
        self.displayName = displayName
        self.sendAddress = sendAddress
        self.receiveAddress = receiveAddress
    }

    // MARK: - Internal Framework Functions

    func updatingReceiveAddress(_ newReceiveAddress: String?) -> Contact {
        return Contact(identifier: identifier,
                       displayName: displayName,
                       sendAddress: sendAddress,
                       receiveAddress: newReceiveAddress)
    }

    func updatingDisplayName(_ newDisplayName: String) -> Contact {
        return Contact(identifier: identifier,
                       displayName: newDisplayName,
                       sendAddress: sendAddress,
                       receiveAddress: receiveAddress)
    }

    func updatingSendAddress(_ newSendAddress: SendAddress?) -> Contact {
        return Contact(identifier: identifier,
                       displayName: displayName,
                       sendAddress: newSendAddress,
                       receiveAddress: receiveAddress)
    }

}

//
//  IPFSAPI.swift
//  HorizonCore
//
//  Created by Connor Power on 03.11.17.
//  Copyright © 2017 Connor Power. All rights reserved.
//

import Foundation
import IPFSWebService
import PromiseKit

/**
 This protocol defines an interface to the IPFS API. It can be
 easily implemented by mock variants for offline testing.
 */
public protocol IPFSAPI {

    // MARK: File Management

    /**
     Adds contents of `file` to IPFS. Directories are not supported at
     this stage.

     - parameter file: The file to be added to IPFS.
     - returns: An `AddResponse` promise.
     */
    func add(file: URL) -> Promise<AddResponse>

    /**
     Displays the data contained by an IPFS or IPNS object(s) at the
     given path. The data returned is a raw byte array and must be interpreted
     by the application itself.

     - parameter arg: The path to the IPFS object(s) to be outputted.
     - returns: A `Data` promise.
     */
    func cat(arg: String) -> Promise<Data>

    // MARK: IPNS

    /**
     Creates a new keypair.

     - parameter keypairName: The name of the key to create.
     - parameter type: The type of the key to create (for instance: 'rsa'
       or 'ed25519'),
     - parameter size: The size of the key to generate.
     - returns: A `KeygenResponse` promise.
     */
    func keygen(keypairName: String, type: DefaultAPI.ModelType_keygen, size: Int) -> Promise<KeygenResponse>

    /**
     Lists all local keypairs.

     - returns: A `ListKeysResponse` promise.
     */
    func listKeys() -> Promise<ListKeysResponse>

    /**
     Removes a keypair.

     - parameter keypairName: The name of the keypair to remove.
     - returns: A `RemoveKeyResponse` promise.
     */
    func removeKey(keypairName: String) -> Promise<RemoveKeyResponse>

    /**
     Renames a keypair.

     - parameter keypairName: The name of the keypair to rename.
     - parameter newKeypairName: The new name to give the keypair.
     - returns: A `RenameKeyResponse` promise.
     */
    func renameKey(keypairName: String, to newKeypairName: String) -> Promise<RenameKeyResponse>

    /**
     Publishes an IPNS name.

     IPNS is a PKI namespace, where names are the hashes of public keys, and
     the private key enables publishing new (signed) values. In both publish
     and resolve, the default name used is the node's own PeerID,
     which is the hash of its public key.

     - parameter arg: The IPFS path of the object to be published.
     - parameter key: The name of the key to be used, as listed by `listKeys(:)`.
       Defaults to the node's own PeerID.
     - returns: A `PublishResponse` promise.
     */
    func publish(arg: String, key: String?) -> Promise<PublishResponse>

    /**
     Resolves an IPNS name.

     IPNS is a PKI namespace, where names are the hashes of public keys, and
     the private key enables publishing new (signed) values. In both publish
     and resolve, the default name used is the node's own PeerID,
     which is the hash of its public key.

     - parameter arg: The IPNS name to resolve.
     - recursive key: Resolve until the result is not an IPNS name. Defaults
       to false.
     - returns: A `ResolveResponse` promise.
     */
    func resolve(arg: String, recursive: Bool?) -> Promise<ResolveResponse>

}

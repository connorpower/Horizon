//
//  IPFSAPI.swift
//  Horizon
//
//  Created by Connor Power on 03.11.17.
//  Copyright © 2017 Semantical GmbH & Co. KG. All rights reserved.
//

import Foundation
import IPFSWebService

/**
 This protocol defines an interface to the IPFS API. It can be
 easily implemented by mock variants for offline testing.
 */
protocol IPFSAPI {

    // MARK: File Management

    /**
     Adds contents of `file` to IPFS. Directories are not supported at
     this stage.

     - parameter file: The file to be added to IPFS.
     - parameter completion: A completion block to be invoked when the
       call returns. Either the `AddResponse` parameter will contain a
       value within it's optional, or the `Error` parameter, but not both.
     */
    func add(file: URL, completion: @escaping ((_ data: AddResponse?, _ error: Error?) -> Void))

    /**
     Displays the data contained by an IPFS or IPNS object(s) at the
     given path. The data returned is a raw byte array and must be interpreted
     by the application itself.

     - parameter arg: The path to the IPFS object(s) to be outputted.
     - parameter completion: A completion block to be invoked when the
       call returns. Either the `Data` parameter will contain
       a value within it's optional, or the `Error` parameter, but not both.
     */
    func cat(arg: String, completion: @escaping ((_ data: Data?, _ error: Error?) -> Void))

    // MARK: IPNS

    /**
     Creates a new keypair.

     - parameter arg: The name of the key to create.
     - parameter type: The type of the key to create (for instance: 'rsa'
       or 'ed25519'),
     - parameter size: The size of the key to generate.
     - parameter completion: A completion block to be invoked when the
       call returns. Either the `KeygenResponse` parameter will contain
       a value within it's optional, or the `Error` parameter, but not both.
     */
    func keygen(arg: String, type: DefaultAPI.ModelType_keygen, size: Int,
                completion: @escaping ((_ data: KeygenResponse?, _ error: Error?) -> Void))

    /**
     Lists all local keypairs.

     - parameter completion: A completion block to be invoked when the
       call returns. Either the `ListKeysResponse` parameter will contain
       a value within it's optional, or the `Error` parameter, but not both.
     */
    func listKeys(completion: @escaping ((_ data: ListKeysResponse?, _ error: Error?) -> Void))

    /**
     Removes a keypair.

     - parameter arg: The name of the keypair to remove.
     - parameter completion: A completion block to be invoked when the
       call returns. Either the `RemoveKeyResponse` parameter will contain
       a value within it's optional, or the `Error` parameter, but not both.
     */
    func removeKey(arg: String, completion: @escaping ((_ data: RemoveKeyResponse?, _ error: Error?) -> Void))

    /**
     Publishes an IPNS name.

     IPNS is a PKI namespace, where names are the hashes of public keys, and
     the private key enables publishing new (signed) values. In both publish
     and resolve, the default name used is the node's own PeerID,
     which is the hash of its public key.

     - parameter arg: The IPFS path of the object to be published.
     - parameter key: The name of the key to be used, as listed by `listKeys(:)`.
       Defaults to the node's own PeerID.
     - parameter completion: A completion block to be invoked when the
       call returns. Either the `PublishResponse` parameter will contain
       a value within it's optional, or the `Error` parameter, but not both.
     */
    func publish(arg: String, key: String?,
                 completion: @escaping ((_ data: PublishResponse?, _ error: Error?) -> Void))

    /**
     Resolves an IPNS name.

     IPNS is a PKI namespace, where names are the hashes of public keys, and
     the private key enables publishing new (signed) values. In both publish
     and resolve, the default name used is the node's own PeerID,
     which is the hash of its public key.

     - parameter arg: The IPNS name to resolve.
     - recursive key: Resolve until the result is not an IPNS name. Defaults
       to false.
     - parameter completion: A completion block to be invoked when the
       call returns. Either the `ResolveResponse` parameter will contain
       a value within it's optional, or the `Error` parameter, but not both.
     */
    func resolve(arg: String, recursive: Bool?,
                 completion: @escaping ((_ data: ResolveResponse?, _ error: Error?) -> Void))

    // MARK: Utility

    /**
     Describes an error which was returned by an API call. This
     utility function is provided in order to deal with the myriad
     of error types and wrapped error types with the various layers
     of networking might return.

     No guarantee is made as to the format of the returned string.

     - parameter error: The error to describe.
     - returns: A string describing the error.
     */
    func describeError(_ error: Error?) -> String

}

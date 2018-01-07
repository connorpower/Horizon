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
 This protocol defines an interface to the IPFS API
 which can be implemented by mock variants for easy
 (and quick) offline testing.
 */
protocol IPFSAPI {

    func add(file: URL, completion: @escaping ((_ data: AddResponse?, _ error: Error?) -> Void))

    func cat(arg: String, completion: @escaping ((_ data: Data?, _ error: Error?) -> Void))

    func keygen(arg: String, type: DefaultAPI.ModelType_keygen, size: Int32,
                completion: @escaping ((_ data: KeygenResponse?, _ error: Error?) -> Void))

    func listKeys(completion: @escaping ((_ data: ListKeysResponse?, _ error: Error?) -> Void))

    func removeKey(arg: String, completion: @escaping ((_ data: RemoveKeyResponse?, _ error: Error?) -> Void))

    func publish(arg: String, key: String?,
                 completion: @escaping ((_ data: PublishResponse?, _ error: Error?) -> Void))

    func resolve(arg: String, recursive: Bool?,
                 completion: @escaping ((_ data: ResolveResponse?, _ error: Error?) -> Void))

    // MARK: Utility

    func printError(_ error: Error?)

}

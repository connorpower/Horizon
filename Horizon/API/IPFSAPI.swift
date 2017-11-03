//
//  IPFSAPI.swift
//  Horizon
//
//  Created by Connor Power on 03.11.17.
//  Copyright © 2017 Semantical GmbH & Co. KG. All rights reserved.
//

import Foundation
import IPFSWebService

struct IPFSAPI: APIProviding {

    // MARK: File Management

    func add(file: URL, completion: @escaping ((_ data: AddResponse?, _ error: Error?) -> Void)) {
        print("Adding file:\n  \"\(file.absoluteString)\"\n")

        DefaultAPI.add(file: file, completion: completion)
    }

    func get(arg: String, completion: @escaping ((_ data: Data?, _ error: Error?) -> Void)) {
        print("Getting file:\n  File: \"\(arg)\"\n")

        DefaultAPI.callGet(arg: arg, completion: completion)
    }

    // MARK: IPNS

    func publish(arg: String, key: String?,
                 completion: @escaping ((_ data: PublishResponse?, _ error: Error?) -> Void)) {
        print("Pubishing file:\n  File: \"\(arg)\"\n  Under key: \"\(key!)\"\n")

        DefaultAPI.publish(arg: arg, key: key, completion: completion)
    }

    func resolve(arg: String, recursive: Bool?,
                 completion: @escaping ((_ data: ResolveResponse?, _ error: Error?) -> Void)) {
        print("Resolving hash:\n  Hash: \"\(arg)\"\n")

        DefaultAPI.resolve(arg: arg, recursive: recursive, completion: completion)
    }

    // MARK: Key Management

    func keygen(arg: String, type: DefaultAPI.ModelType_keygen, size: Int32,
                completion: @escaping ((_ data: KeygenResponse?, _ error: Error?) -> Void)) {
        print("Generating key:\n  Name: \"\(arg)\"\n  Type: \"\(type.rawValue)\"\n  Size: \"\(size)\"\n")

        DefaultAPI.keygen(arg: arg, type: type, size: size, completion: completion)
    }

    func listKeys(completion: @escaping ((_ data: ListKeysResponse?, _ error: Error?) -> Void)) {
        print("Listing keys...\n")

        DefaultAPI.listKeys(completion: completion)
    }

    func removeKey(arg: String, completion: @escaping ((_ data: RemoveKeyResponse?, _ error: Error?) -> Void)) {
        print("Removing key:\n  Name: \"\(arg)\"\n")

        DefaultAPI.removeKey(arg: arg, completion: completion)
    }

}

//
//  MockIPFSWebserviceAPI.swift
//  Horizon
//
//  Created by Connor Power on 03.11.17.
//  Copyright © 2017 Semantical GmbH & Co. KG. All rights reserved.
//

import Foundation
import IPFSWebService

struct MockIPFSWebserviceAPI: IPFSAPI {

    // MARK: File Management

    func add(file: URL, completion: @escaping ((_ data: AddResponse?, _ error: Error?) -> Void)) {
        let response = AddResponse()
        response.name = "The Cathedral and the Bazaar.pdf"
        response.hash = "QmU6A9DYK4N7dvgcrmr9YRjJ4RNxAE6HnMjBBPLGedqVT7"
        response.size = "193974"

        completion(response, nil)
    }

    func cat(arg: String, completion: @escaping ((_ data: Data?, _ error: Error?) -> Void)) {
        let fileURL = Bundle.main.url(forResource: "The Cathedral and the Bazaar", withExtension: "pdf")!
        let data = try? Data(contentsOf: fileURL, options: [])

        completion(data, nil)
    }

    // MARK: IPNS

    func publish(arg: String, key: String?,
                 completion: @escaping ((_ data: PublishResponse?, _ error: Error?) -> Void)) {
        let response = PublishResponse()
        response.name = "QmWwVSYrc3fQcBDXBFmpiFBcfmGeqyc7Nci8imT3RnbydH"
        response.value = "/ipfs/QmU6A9DYK4N7dvgcrmr9YRjJ4RNxAE6HnMjBBPLGedqVT7"

        completion(response, nil)
    }

    func resolve(arg: String, recursive: Bool?,
                 completion: @escaping ((_ data: ResolveResponse?, _ error: Error?) -> Void)) {
        let response = ResolveResponse()
        response.path = "/ipfs/QmU6A9DYK4N7dvgcrmr9YRjJ4RNxAE6HnMjBBPLGedqVT7"

        completion(response, nil)
    }

    // MARK: Key Management

    func keygen(arg: String, type: DefaultAPI.ModelType_keygen, size: Int32,
                completion: @escaping ((_ data: KeygenResponse?, _ error: Error?) -> Void)) {}

    func listKeys(completion: @escaping ((_ data: ListKeysResponse?, _ error: Error?) -> Void)) {}

    func removeKey(arg: String, completion: @escaping ((_ data: RemoveKeyResponse?, _ error: Error?) -> Void)) {}

    // MARK: Utility

    func printError(_ error: Error?) {}

}

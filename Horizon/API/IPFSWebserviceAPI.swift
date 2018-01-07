//
//  IPFSAPI.swift
//  Horizon
//
//  Created by Connor Power on 03.11.17.
//  Copyright © 2017 Semantical GmbH & Co. KG. All rights reserved.
//

import Foundation
import IPFSWebService
import Alamofire
import os.log

struct IPFSWebserviceAPI: IPFSAPI {

    // MARK: File Management

    func add(file: URL, completion: @escaping ((_ response: AddResponse?, _ error: Error?) -> Void)) {
        os_log("Adding file to IPFS: %s", log: Loggers.network, type: .info, file.absoluteString)

        DefaultAPI.add(file: file) { (response, error) in
            if let response = response {
                os_log("Added file %s to IPFS with hash %s, size %s", log: Loggers.network, type: .info,
                       response.name ?? "[no name]",
                       response.hash ?? "[no hash]",
                       response.size ?? "[no size]")
            } else {
                os_log("Failed to add file %s to IPFS. %s", log: Loggers.network, type: .error,
                       self.describeError(error))
            }

            completion(response, error)
        }
    }

    func cat(arg: String, completion: @escaping ((_ data: Data?, _ error: Error?) -> Void)) {
        os_log("Catting object from IPFS: %s", log: Loggers.network, type: .info, arg)

        DefaultAPI.cat(arg: arg) { (data, error) in
            if data != nil {
                os_log("Cat of %s from IPFS returned %d bytes", log: Loggers.network, type: .info,
                       data?.count ?? 0)
            } else if let error = error {
                os_log("Failed to cat %s from IPFS. %s", log: Loggers.network, type: .error,
                       self.describeError(error))
            }

            completion(data, error)
        }
    }

    // MARK: IPNS

    func publish(arg: String, key: String?,
                 completion: @escaping ((_ response: PublishResponse?, _ error: Error?) -> Void)) {
        os_log("Publishing file %s under key %s", log: Loggers.network, type: .info, arg, key ?? "[Node's Own PeerID]")

        DefaultAPI.publish(arg: arg, key: key) { (response, error) in
            if let response = response {
                os_log("Published file with name %s under key %s", log: Loggers.network, type: .info,
                       response.name ?? "[no name]",
                       response.value ?? "[no value]")
            } else {
                os_log("Failed to publish file %s. %s", log: Loggers.network, type: .error,
                       arg, self.describeError(error))
            }

            completion(response, error)
        }
    }

    func resolve(arg: String, recursive: Bool?,
                 completion: @escaping ((_ response: ResolveResponse?, _ error: Error?) -> Void)) {
        os_log("Resolving hash %s", log: Loggers.network, type: .info, arg)

        DefaultAPI.resolve(arg: arg, recursive: recursive) { (response, error) in
            if let response = response {
                os_log("Resolved hash %s to path %s", log: Loggers.network, type: .info,
                       arg, response.path ?? "[no path]")
            } else {
                os_log("Failed to resolve hash %s", log: Loggers.network, type: .error, arg)
            }

            completion(response, error)
        }
    }

    func keygen(arg: String, type: DefaultAPI.ModelType_keygen, size: Int32,
                completion: @escaping ((_ response: KeygenResponse?, _ error: Error?) -> Void)) {
        os_log("Generating key %s of type %s, size %d", log: Loggers.network, type: .info, arg, type.rawValue, size)

        DefaultAPI.keygen(arg: arg, type: type, size: size) { (response, error) in
            if let response = response {
                os_log("Generated key %s with ID %s", log: Loggers.network, type: .info, arg, response.id ?? "[no ID]")
            } else {
                os_log("Failed to generate key %s. %s", log: Loggers.network, type: .error,
                       arg, self.describeError(error))
            }

            completion(response, error)
        }
    }

    func listKeys(completion: @escaping ((_ response: ListKeysResponse?, _ error: Error?) -> Void)) {
        os_log("Listing keypairs", log: Loggers.network, type: .info)

        DefaultAPI.listKeys { (response, error) in
            if let response = response {
                let keys = (response.keys ?? []).map({"\($0.name ?? "[no name]"): \($0.id ?? "[no ID]")"})
                os_log("Found keypairs: ", log: Loggers.network, type: .info, keys.joined(separator: ", "))
            } else {
                os_log("Failed to list keypairs. %s", log: Loggers.network, type: .error, self.describeError(error))
            }

            completion(response, error)
        }
    }

    func removeKey(arg: String, completion: @escaping ((_ response: RemoveKeyResponse?, _ error: Error?) -> Void)) {
        os_log("Removing key %s", log: Loggers.network, type: .info, arg)

        DefaultAPI.removeKey(arg: arg) { (response, error) in
            if response != nil {
                os_log("Removed key %s", log: Loggers.network, type: .info, arg)
            } else {
                os_log("Failed to removed key %s. %s", log: Loggers.network, type: .info,
                       arg, self.describeError(error))
            }

            completion(response, error)
        }
    }

    // MARK: - Utility

    func describeError(_ error: Error?) -> String {
        var string = ""

        if let errorResponse = error as? ErrorResponse {
            switch errorResponse {
            case .Error(let statusCode, let data, let error):
                string += "HTTP Error – status code: \(statusCode). "
                if let data = data, let stringData = String(data: data, encoding: .utf8) {
                    string += "data:  \(stringData). "
                }
                // Recurse
                string += "Wrapped error: " + describeError(error)
            }
        } else if let afError = error as? AFError, let description = afError.errorDescription {
            string += description + " "
        } else {
            string += String(describing: error) + " "
        }

        return string
    }

}

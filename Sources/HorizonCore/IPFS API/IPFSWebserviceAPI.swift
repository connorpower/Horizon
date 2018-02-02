//
//  IPFSAPI.swift
//  HorizonCore
//
//  Created by Connor Power on 03.11.17.
//  Copyright © 2017 Semantical GmbH & Co. KG. All rights reserved.
//

import Foundation
import IPFSWebService
import Alamofire
import os.log

public struct IPFSWebserviceAPI: IPFSAPI {

    // MARK: Variables

    /**
     A dependency injected logger provider to be used by all operations
     within this struct.
     */
    public let logProvider: LogProvider

    // MARK: Initialization

    public init(logProvider: LogProvider) {
        self.logProvider = logProvider
    }

    // MARK: File Management

    public func add(file: URL, completion: @escaping ((_ response: AddResponse?, _ error: Error?) -> Void)) {
        os_log("Adding file to IPFS: %{public}s", log: logProvider.network, type: .info, file.absoluteString)

        DefaultAPI.add(file: file) { (response, error) in
            if let response = response {
                os_log("Added file %{public}s to IPFS with hash %{public}s, size %{public}s",
                       log: self.logProvider.network, type: .info,
                       response.name, response.hash, response.size)
            } else {
                os_log("Failed to add file %{public}s to IPFS. %{public}s",
                       log: self.logProvider.network, type: .error, self.describeError(error))
            }

            completion(response, error)
        }
    }

    public func cat(arg: String, completion: @escaping ((_ data: Data?, _ error: Error?) -> Void)) {
        os_log("Catting object from IPFS: %{public}s", log: logProvider.network, type: .info, arg)

        DefaultAPI.cat(arg: arg) { (data, error) in
            if data != nil {
                os_log("Cat of %{public}s from IPFS returned %d bytes",
                       log: self.logProvider.network, type: .info, data?.count ?? 0)
            } else if let error = error {
                os_log("Failed to cat %{public}s from IPFS. %{public}s",
                       log: self.logProvider.network, type: .error, self.describeError(error))
            }

            completion(data, error)
        }
    }

    // MARK: IPNS

    public func publish(arg: String, key: String?,
                        completion: @escaping ((_ response: PublishResponse?, _ error: Error?) -> Void)) {
        os_log("Publishing file %{public}s under key %{public}s", log: logProvider.network, type: .info,
               arg, key ?? "[Node's Own PeerID]")

        DefaultAPI.publish(arg: arg, key: key) { (response, error) in
            if let response = response {
                os_log("Published file with name %{public}s under key %{public}s",
                       log: self.logProvider.network, type: .info, response.name, response.value)
            } else {
                os_log("Failed to publish file %{public}s. %{public}s",
                       log: self.logProvider.network, type: .error, arg, self.describeError(error))
            }

            completion(response, error)
        }
    }

    public func resolve(arg: String, recursive: Bool?,
                        completion: @escaping ((_ response: ResolveResponse?, _ error: Error?) -> Void)) {
        os_log("Resolving hash %{public}s", log: logProvider.network, type: .info, arg)

        DefaultAPI.resolve(arg: arg, recursive: recursive) { (response, error) in
            if let response = response {
                os_log("Resolved hash %{public}s to path %{public}s",
                       log: self.logProvider.network, type: .info, arg, response.path)
            } else {
                os_log("Failed to resolve hash %{public}s",
                       log: self.logProvider.network, type: .error, arg)
            }

            completion(response, error)
        }
    }

    public func keygen(arg: String, type: DefaultAPI.ModelType_keygen, size: Int,
                       completion: @escaping ((_ response: KeygenResponse?, _ error: Error?) -> Void)) {
        os_log("Generating key %{public}s of type %{public}s, size %d", log: logProvider.network, type: .info,
               arg, type.rawValue, size)

        DefaultAPI.keygen(arg: arg, type: type, size: size) { (response, error) in
            if let response = response {
                os_log("Generated key %{public}s with ID %{public}s",
                       log: self.logProvider.network, type: .info, arg, response.id)
            } else {
                os_log("Failed to generate key %{public}s. %{public}s",
                       log: self.logProvider.network, type: .error, arg, self.describeError(error))
            }

            completion(response, error)
        }
    }

    public func listKeys(completion: @escaping ((_ response: ListKeysResponse?, _ error: Error?) -> Void)) {
        os_log("Listing keypairs", log: logProvider.network, type: .info)

        DefaultAPI.listKeys { (response, error) in
            if let response = response {
                let keys = response.keys.map({"\($0.name): \($0.id)"})
                os_log("Found keypairs: %{public}s", log: self.logProvider.network,
                       type: .info, keys.joined(separator: ", "))
            } else {
                os_log("Failed to list keypairs. %{public}s", log: self.logProvider.network, type: .error,
                       self.describeError(error))
            }

            completion(response, error)
        }
    }

    public func removeKey(arg: String,
                          completion: @escaping ((_ response: RemoveKeyResponse?, _ error: Error?) -> Void)) {
        os_log("Removing key %{public}s", log: logProvider.network, type: .info, arg)

        DefaultAPI.removeKey(arg: arg) { (response, error) in
            if response != nil {
                os_log("Removed key %{public}s", log: self.logProvider.network, type: .info, arg)
            } else {
                os_log("Failed to removed key %{public}s. %{public}s",
                       log: self.logProvider.network, type: .info, arg, self.describeError(error))
            }

            completion(response, error)
        }
    }

    // MARK: - Utility

    public func describeError(_ error: Error?) -> String {
        var string = ""

        if let errorResponse = error as? ErrorResponse {
            switch errorResponse {
            case .error(let statusCode, let data, let error):
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

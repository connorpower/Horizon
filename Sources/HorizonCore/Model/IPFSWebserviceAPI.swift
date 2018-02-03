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
import PromiseKit
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

    // MARK: IPFSAPI

    public func add(file: URL) -> Promise<AddResponse> {
        os_log("Adding file to IPFS: %{public}s", log: logProvider.network, type: .info, file.absoluteString)

        return Promise { fulfill, reject in
            DefaultAPI.add(file: file) { (response, error) in
                if let response = response {
                    os_log("Added file %{public}s to IPFS with hash %{public}s, size %{public}s",
                           log: self.logProvider.network, type: .info,
                           response.name, response.hash, response.size)
                    fulfill(response)
                } else if let error = error {
                    os_log("Failed to add file %{public}s to IPFS. %{public}s",
                           log: self.logProvider.network, type: .error, self.describeError(error))
                    reject(error)
                } else {
                    reject(PMKError.invalidCallingConvention)
                }
            }
        }
    }

    public func cat(arg: String) -> Promise<Data> {
        os_log("Catting object from IPFS: %{public}s", log: logProvider.network, type: .info, arg)

        return Promise { fulfill, reject in
            DefaultAPI.cat(arg: arg) { (data, error) in
                if let data = data {
                    os_log("Cat of %{public}s from IPFS returned %d bytes",
                           log: self.logProvider.network, type: .info, data.count)
                    fulfill(data)
                } else if let error = error {
                    os_log("Failed to cat %{public}s from IPFS. %{public}s",
                           log: self.logProvider.network, type: .error, self.describeError(error))
                    reject(error)
                } else {
                    reject(PMKError.invalidCallingConvention)
                }
            }
        }
    }

    public func keygen(arg: String, type: DefaultAPI.ModelType_keygen, size: Int) -> Promise<KeygenResponse> {
        os_log("Generating key %{public}s of type %{public}s, size %d", log: logProvider.network, type: .info,
               arg, type.rawValue, size)

        return Promise { fulfill, reject in
            DefaultAPI.keygen(arg: arg, type: type, size: size) { (response, error) in
                if let response = response {
                    os_log("Generated key %{public}s with ID %{public}s",
                           log: self.logProvider.network, type: .info, arg, response.id)
                    fulfill(response)
                } else if let error = error {
                    os_log("Failed to generate key %{public}s. %{public}s",
                           log: self.logProvider.network, type: .error, arg, self.describeError(error))
                    reject(error)
                } else {
                    reject(PMKError.invalidCallingConvention)
                }
            }
        }
    }

    public func listKeys() -> Promise<ListKeysResponse> {
        os_log("Listing keypairs", log: logProvider.network, type: .info)

        return Promise { fulfill, reject in
            DefaultAPI.listKeys { (response, error) in
                if let response = response {
                    let keys = response.keys.map({"\($0.name): \($0.id)"})
                    os_log("Found keypairs: %{public}s", log: self.logProvider.network,
                           type: .info, keys.joined(separator: ", "))
                    fulfill(response)
                } else if let error = error {
                    os_log("Failed to list keypairs. %{public}s", log: self.logProvider.network, type: .error,
                           self.describeError(error))
                    reject(error)
                } else {
                    reject(PMKError.invalidCallingConvention)
                }
            }
        }
    }

    public func removeKey(keypairName: String) -> Promise<RemoveKeyResponse> {
        os_log("Removing key %{public}s", log: logProvider.network, type: .info, keypairName)

        return Promise { fulfill, reject in
            DefaultAPI.removeKey(arg: keypairName) { (response, error) in
                if let response = response {
                    os_log("Removed key %{public}s", log: self.logProvider.network, type: .info, keypairName)
                    fulfill(response)
                } else if let error = error {
                    os_log("Failed to removed key %{public}s. %{public}s",
                           log: self.logProvider.network, type: .info, keypairName, self.describeError(error))
                    reject(error)
                } else {
                    reject(PMKError.invalidCallingConvention)
                }
            }
        }
    }

    public func publish(arg: String, key: String?) -> Promise<PublishResponse> {
        os_log("Publishing file %{public}s under key %{public}s", log: logProvider.network, type: .info,
               arg, key ?? "[Node's Own PeerID]")

        return Promise { fulfill, reject in
            DefaultAPI.publish(arg: arg, key: key) { (response, error) in
                if let response = response {
                    os_log("Published file with name %{public}s under key %{public}s",
                           log: self.logProvider.network, type: .info, response.name, response.value)
                    fulfill(response)
                } else if let error = error {
                    os_log("Failed to publish file %{public}s. %{public}s",
                           log: self.logProvider.network, type: .error, arg, self.describeError(error))
                    reject(error)
                } else {
                    reject(PMKError.invalidCallingConvention)
                }
            }
        }
    }

    public func resolve(arg: String, recursive: Bool?) -> Promise<ResolveResponse> {
        os_log("Resolving hash %{public}s", log: logProvider.network, type: .info, arg)

        return Promise { fulfill, reject in
            DefaultAPI.resolve(arg: arg, recursive: recursive) { (response, error) in
                if let response = response {
                    os_log("Resolved hash %{public}s to path %{public}s",
                           log: self.logProvider.network, type: .info, arg, response.path)
                    fulfill(response)
                } else if let error = error {
                    os_log("Failed to resolve hash %{public}s",
                           log: self.logProvider.network, type: .error, arg)
                    reject(error)
                } else {
                    reject(PMKError.invalidCallingConvention)
                }
            }
        }
    }

    // MARK: Private Functions

    /**
     Describes an error which was returned by an API call. This
     utility function is provided in order to deal with the myriad
     of error types and wrapped error types with the various layers
     of networking might return.

     No guarantee is made as to the format of the returned string.

     - parameter error: The error to describe.
     - returns: A string describing the error.
     */
    private func describeError(_ error: Error?) -> String {
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

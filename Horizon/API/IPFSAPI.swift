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

struct IPFSAPI: APIProviding {

    // MARK: File Management

    func add(file: URL, completion: @escaping ((_ response: AddResponse?, _ error: Error?) -> Void)) {
        print("Adding file:\n  \"\(file.absoluteString)\"\n")

        DefaultAPI.add(file: file) { (response, error) in
            if let response = response {
                print("Added file:")
                print("  Name: \"\(response.name!)\"\n  Hash: \"\(response.hash!)\"\n  Size: \"\(response.size!)\"\n")
            }

            completion(response, error)
        }
    }

    func get(arg: String, completion: @escaping ((_ data: Data?, _ error: Error?) -> Void)) {
        print("Getting file:\n  File: \"\(arg)\"\n")

        DefaultAPI.callGet(arg: arg) { (data, error) in
            if data != nil {
                print("Got file\n")
            }

            completion(data, error)
        }
    }

    // MARK: IPNS

    func publish(arg: String, key: String?,
                 completion: @escaping ((_ response: PublishResponse?, _ error: Error?) -> Void)) {
        print("Pubishing file:\n  File: \"\(arg)\"\n  Under key: \"\(key!)\"\n")

        DefaultAPI.publish(arg: arg, key: key) { (response, error) in
            if let response = response {
                print("Published file:\n  Name: \"\(response.name!)\"\n  Value: \"\(response.value!)\"\n")
            }

            completion(response, error)
        }
    }

    func resolve(arg: String, recursive: Bool?,
                 completion: @escaping ((_ response: ResolveResponse?, _ error: Error?) -> Void)) {
        print("Resolving hash:\n  Hash: \"\(arg)\"\n")

        DefaultAPI.resolve(arg: arg, recursive: recursive) { (response, error) in
            if let response = response {
                print("Resolved hash:\n  Path: \"\(response.path!)\"\n")
            }

            completion(response, error)
        }
    }

    // MARK: Key Management

    func keygen(arg: String, type: DefaultAPI.ModelType_keygen, size: Int32,
                completion: @escaping ((_ response: KeygenResponse?, _ error: Error?) -> Void)) {
        print("Generating key:\n  Name: \"\(arg)\"\n  Type: \"\(type.rawValue)\"\n  Size: \"\(size)\"\n")

        DefaultAPI.keygen(arg: arg, type: type, size: size) { (response, error) in
            if let response = response {
                print("Generated key:\n  Name: \"\(response.name!)\"\n  ID: \"\(response.id!)\"\n")
            }

            completion(response, error)
        }
    }

    func listKeys(completion: @escaping ((_ response: ListKeysResponse?, _ error: Error?) -> Void)) {
        print("Listing keys...\n")

        DefaultAPI.listKeys { (response, error) in
            if let response = response {
                print("Listed keys:")
                for key in response.keys! {
                    print("  Name: \"\(key.name!)\"\n  ID: \"\(key.id!)\"")
                }
                print("")
            }

            completion(response, error)
        }
    }

    func removeKey(arg: String, completion: @escaping ((_ response: RemoveKeyResponse?, _ error: Error?) -> Void)) {
        print("Removing key:\n  Name: \"\(arg)\"\n")

        DefaultAPI.removeKey(arg: arg) { (response, error) in
            if response != nil {
                print("Removed key.")
            }

            completion(response, error)
        }
    }

    // MARK: Utility

    func printError(_ error: Error?) {
        if let errorResponse = error as? ErrorResponse {
            switch errorResponse {
            case .Error(let statusCode, let data, let error):
                print("Error (\(statusCode)):")
                if let data = data, let string = String(data: data, encoding: .utf8) {
                    print("  \(string)")
                }
                // Recurse
                printError(error)
            }
        } else if let afError = error as? AFError, let description = afError.errorDescription {
            print(description)
        } else {
            print(String(describing: error))
        }
    }

}

//
//  MockIPFSAPI.swift
//  HorizonCoreTests
//
//  Created by Connor Power on 09.02.18.
//  Copyright © 2018 Semantical GmbH & Co. KG. All rights reserved.
//

import Foundation
import IPFSWebService
import PromiseKit
@testable import HorizonCore

class MockIPFSAPI: IPFSAPI {

    var addResponse: ((URL) -> Promise<AddResponse>)?
    var catResponse: ((String) -> Promise<Data>)?
    var keygenResponse: ((String, DefaultAPI.ModelType_keygen, Int) -> Promise<KeygenResponse>)?
    var listKeysResponse: (() -> Promise<ListKeysResponse>)?
    var removeKeyResponse: ((String) -> Promise<RemoveKeyResponse>)?
    var renameKeyResponse: ((String, String) -> Promise<RenameKeyResponse>)?
    var publishResponse: ((String, String?) -> Promise<PublishResponse>)?
    var resolveResponse: ((String, Bool?) -> Promise<ResolveResponse>)?

    func add(file: URL) -> Promise<AddResponse> {
        guard let addResponse = addResponse else {
            fatalError()
        }
        return addResponse(file)
    }

    func cat(arg: String) -> Promise<Data> {
        guard let catResponse = catResponse else {
            fatalError()
        }
        return catResponse(arg)
    }

    func keygen(keypairName: String, type: DefaultAPI.ModelType_keygen, size: Int) -> Promise<KeygenResponse> {
        guard let keygenResponse = keygenResponse else {
            fatalError()
        }
        return keygenResponse(keypairName, type, size)
    }

    func listKeys() -> Promise<ListKeysResponse> {
        guard let listKeysResponse = listKeysResponse else {
            fatalError()
        }
        return listKeysResponse()
    }

    func removeKey(keypairName: String) -> Promise<RemoveKeyResponse> {
        guard let removeKeyResponse = removeKeyResponse else {
            fatalError()
        }
        return removeKeyResponse(keypairName)
    }

    func renameKey(keypairName: String, to newKeypairName: String) -> Promise<RenameKeyResponse> {
        guard let renameKeyResponse = renameKeyResponse else {
            fatalError()
        }
        return renameKeyResponse(keypairName, newKeypairName)
    }

    func publish(arg: String, key: String?) -> Promise<PublishResponse> {
        guard let publishResponse = publishResponse else {
            fatalError()
        }
        return publishResponse(arg, key)
    }

    func resolve(arg: String, recursive: Bool?) -> Promise<ResolveResponse> {
        guard let resolveResponse = resolveResponse else {
            fatalError()
        }
        return resolveResponse(arg, recursive)
    }

}

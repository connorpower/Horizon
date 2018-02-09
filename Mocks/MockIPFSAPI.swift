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

    var addResponse: (() -> AddResponse)?
    var catResponse: (() -> Data)?
    var keygenResponse: (() -> KeygenResponse)?
    var listKeysResponse: (() -> ListKeysResponse)?
    var removeKeyResponse: (() -> RemoveKeyResponse)?
    var renameKeyResponse: (() -> RenameKeyResponse)?
    var publishResponse: (() -> PublishResponse)?
    var resolveResponse: (() -> ResolveResponse)?

    func add(file: URL) -> Promise<AddResponse> {
        guard let addResponse = addResponse else {
            fatalError()
        }
        return Promise(value: addResponse())
    }

    func cat(arg: String) -> Promise<Data> {
        guard let catResponse = catResponse else {
            fatalError()
        }
        return Promise(value: catResponse())
    }

    func keygen(keypairName: String, type: DefaultAPI.ModelType_keygen, size: Int) -> Promise<KeygenResponse> {
        guard let keygenResponse = keygenResponse else {
            fatalError()
        }
        return Promise(value: keygenResponse())
    }

    func listKeys() -> Promise<ListKeysResponse> {
        guard let listKeysResponse = listKeysResponse else {
            fatalError()
        }
        return Promise(value: listKeysResponse())
    }

    func removeKey(keypairName: String) -> Promise<RemoveKeyResponse> {
        guard let removeKeyResponse = removeKeyResponse else {
            fatalError()
        }
        return Promise(value: removeKeyResponse())
    }

    func renameKey(keypairName: String, to newKeypairName: String) -> Promise<RenameKeyResponse> {
        guard let renameKeyResponse = renameKeyResponse else {
            fatalError()
        }
        return Promise(value: renameKeyResponse())
    }

    func publish(arg: String, key: String?) -> Promise<PublishResponse> {
        guard let publishResponse = publishResponse else {
            fatalError()
        }
        return Promise(value: publishResponse())
    }

    func resolve(arg: String, recursive: Bool?) -> Promise<ResolveResponse> {
        guard let resolveResponse = resolveResponse else {
            fatalError()
        }
        return Promise(value: resolveResponse())
    }

}

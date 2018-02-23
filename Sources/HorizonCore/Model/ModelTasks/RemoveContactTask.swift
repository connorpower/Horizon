//
//  RemoveContactTask.swift
//  HorizonCore
//
//  Created by Connor Power on 23.02.18.
//

import Foundation
import PromiseKit
import IPFSWebService

struct RemoveContactTask: ModelTask {

    // MARK: - Properties

    private let model: Model

    // MARK: - Initializer

    init(model: Model) {
        self.model = model
    }

    // MARK: - Functions

    func removeContact(name: String) -> Promise<Void> {
        // Dont rely entirely on the keypair name or the contact. The
        // contact was potentially deleted, leaving behind a dangling IPNS keypair or vice versa.
        let contact = self.model.contact(named: name)
        let keypairName = "\(model.config.persistentStoreKeys.keypairPrefix).\(name)"

        return firstly {
            return self.model.api.listKeys()
        }.then { listKeysResponse -> Promise<Void> in

            // Branch 1: the underlying IPFS key is missing, but we may have a model contact object.
            guard listKeysResponse.keys.map({ $0.name }).contains(keypairName) else {
                if let contact = contact {
                    self.model.persistentStore.removeContact(contact)
                    self.model.eventCallback?(.propertiesDidChange(contact))

                    return Promise(value: ())
                } else {
                    throw HorizonError.contactOperationFailed(reason: .contactDoesNotExist)
                }
            }

            // Branch 2: the underlying IPFS key present, and we may have a model contact object.
            self.model.eventCallback?(.removeKeyDidStart(name))
            return firstly {
                return self.model.api.removeKey(keypairName: keypairName)
            }.then { _ in
                if let contact = contact {
                    self.model.persistentStore.removeContact(contact)
                    self.model.eventCallback?(.propertiesDidChange(contact))
                }
                return Promise(value: ())
            }
        }.catch { error in
            let horizonError: HorizonError
            if let castError = error as? HorizonError {
                horizonError = castError
            } else {
                horizonError = HorizonError.contactOperationFailed(reason: .unknown(error))
            }
            self.model.eventCallback?(.errorEvent(horizonError))
        }
    }


}

//
//  RenameContactTask.swift
//  HorizonCore
//
//  Created by Connor Power on 23.02.18.
//

import Foundation
import PromiseKit
import IPFSWebService

struct RenameContactTask: ModelTask {

    // MARK: - Properties

    private let model: Model

    // MARK: - Initializer

    init(model: Model) {
        self.model = model
    }

    // MARK: - Functions

    func renameContact(_ name: String, to newName: String) -> Promise<Contact> {
        let keypairName = "\(model.configuration.persistentStoreKeys.keypairPrefix).\(name)"
        let newKeypairName = "\(model.configuration.persistentStoreKeys.keypairPrefix).\(newName)"

        guard let contact = self.model.contact(named: name) else {
            return Promise<Contact>(error: HorizonError.contactOperationFailed(reason: .contactDoesNotExist))
        }

        guard self.model.contact(named: newName) == nil else {
            return Promise<Contact>(error: HorizonError.contactOperationFailed(reason: .contactAlreadyExists))
        }

        return firstly {
            return self.model.api.listKeys()
        }.then { listKeysResponse -> Promise<RenameKeyResponse> in
            let currentNames = listKeysResponse.keys.map({ $0.name })
            if !currentNames.contains(keypairName) {
                throw HorizonError.contactOperationFailed(reason: .contactDoesNotExist)
            }
            if currentNames.contains(newKeypairName) {
                throw HorizonError.contactOperationFailed(reason: .contactAlreadyExists)
            }

            self.model.eventCallback?(.renameKeyDidStart(keypairName, newKeypairName))
            return self.model.api.renameKey(keypairName: keypairName, to: newKeypairName)
        }.then { renameKeyResponse in
            let sendAddress = SendAddress(address: renameKeyResponse.id, keypairName: renameKeyResponse.now)
            let updatedContact = contact.updatingDisplayName(newName).updatingSendAddress(sendAddress)

            self.model.persistentStore.createOrUpdateContact(updatedContact)
            self.model.eventCallback?(.propertiesDidChange(updatedContact))
            return Promise(value: updatedContact)
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

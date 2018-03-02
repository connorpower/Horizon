//
//  AddContactTask.swift
//  HorizonCore
//
//  Created by Connor Power on 23.02.18.
//

import Foundation
import PromiseKit
import IPFSWebService

struct AddContactTask: ModelTask {

    // MARK: - Properties

    private let model: Model

    // MARK: - Initializer

    init(model: Model) {
        self.model = model
    }

    // MARK: - Functions

    func addContact(name: String) -> Promise<Contact> {
        let keypairName = "\(model.configuration.persistentStoreKeys.keypairPrefix).\(name)"

        guard model.contact(named: name) == nil else {
            return Promise(error: HorizonError.contactOperationFailed(reason: .contactAlreadyExists))
        }

        return firstly {
            return self.model.api.listKeys()
        }.then { listKeysResponse  -> Promise<KeygenResponse> in
            if listKeysResponse.keys.map({ $0.name }).contains(keypairName) {
                throw HorizonError.contactOperationFailed(reason: .contactAlreadyExists)
            }

            self.model.eventCallback?(.keygenDidStart(keypairName))
            return self.model.api.keygen(keypairName: keypairName, type: .rsa, size: 2048)
        }.then { keygenResponse in
            let sendAddress = SendAddress(address: keygenResponse.id, keypairName: keygenResponse.name)
            let contact = Contact(identifier: UUID(), displayName: name,
                                  sendAddress: sendAddress, receiveAddress: nil)

            self.model.persistentStore.createOrUpdateContact(contact)
            self.model.eventCallback?(.propertiesDidChange(contact))

            // Immediately publish the file list, so that a sync for the other contact succeeds (Issue #56).
            return PublishFileListTask(model: self.model).publishFileList(for: contact)
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

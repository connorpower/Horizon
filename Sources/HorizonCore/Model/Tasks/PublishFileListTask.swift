//
//  PublishFileListTask.swift
//  HorizonCore
//
//  Created by Connor Power on 02.03.18.
//

import Foundation
import PromiseKit
import IPFSWebService

struct PublishFileListTask: ModelTask {

    // MARK: - Properties

    private let model: Model

    // MARK: - Initializer

    init(model: Model) {
        self.model = model
    }

    // MARK: - Functions

    func publishFileList(for contact: Contact) -> Promise<Contact> {
        guard let sendAddress = contact.sendAddress else {
            return Promise(error: HorizonError.fileOperationFailed(reason: .sendAddressNotSet))
        }
        guard let newSendListURL = FileManager.default.encodeAsJSONInTemporaryFile(contact.sendList.files) else {
            return Promise(error: HorizonError.fileOperationFailed(reason: .failedToEncodeFileListToTemporaryFile))
        }

        return firstly { () -> Promise<(AddResponse, Contact)> in
            self.model.eventCallback?(.addingProvidedFileListToIPFSDidStart(contact))

            return self.model.api.add(file: newSendListURL).then { ($0, contact) }
        }.then { addFileFesponse, contact -> Promise<(PublishResponse, Contact)> in
            self.model.eventCallback?(.publishingFileListToIPNSDidStart(contact))

            let sendListHash = addFileFesponse.hash
            let updatedSendList = contact.sendList.updatingHash(sendListHash)
            let updatedContact = contact.updatingSendList(updatedSendList)
            self.model.persistentStore.createOrUpdateContact(updatedContact)

            // Keep passing the updated contact forward
            return self.model.api.publish(arg: sendListHash, key: sendAddress.keypairName).then { ($0, updatedContact) }
        }.then { _, contact in
            return Promise(value: contact)
        }.catch { error in
            let horizonError: HorizonError
            if let castError = error as? HorizonError {
                horizonError = castError
            } else {
                horizonError = HorizonError.fileOperationFailed(reason: .unknown(error))
            }
            self.model.eventCallback?(.errorEvent(horizonError))
        }
    }

}

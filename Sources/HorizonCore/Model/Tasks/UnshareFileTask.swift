//
//  UnshareFileTask.swift
//  HorizonCore
//
//  Created by Connor Power on 23.02.18.
//

import Foundation
import PromiseKit
import IPFSWebService

struct UnshareFileTask: ModelTask {

    // MARK: - Properties

    private let model: Model

    // MARK: - Initializer

    init(model: Model) {
        self.model = model
    }

    // MARK: - Functions

    func unshareFiles(_ files: [File], with contact: Contact) -> Promise<Contact> {
        guard let sendAddress = contact.sendAddress else {
            return Promise(error: HorizonError.fileOperationFailed(reason: .sendAddressNotSet))
        }

        guard contact.sendList.files.filter({ files.contains($0) }).first != nil else {
            return Promise(error: HorizonError.fileOperationFailed(reason: .fileNotShared))
        }

        return firstly { () -> Promise<(AddResponse, Contact)> in
            let filteredFiles = contact.sendList.files.filter { !files.contains($0) }
            let updatedSendList = FileList(hash: nil, files: filteredFiles)
            let updatedContact = contact.updatingSendList(updatedSendList)

            guard let newSendListURL = FileManager.default.encodeAsJSONInTemporaryFile(updatedSendList.files) else {
                throw HorizonError.fileOperationFailed(reason: .failedToEncodeFileListToTemporaryFile)
            }

            self.model.eventCallback?(.addingProvidedFileListToIPFSDidStart(contact))

            // Keep passing the updated contact forward
            return self.model.api.add(file: newSendListURL).then { ($0, updatedContact) }
        }.then { addFileFesponse, contact -> Promise<(PublishResponse, Contact)> in
            self.model.eventCallback?(.publishingFileListToIPNSDidStart(contact))

            let sendListHash = addFileFesponse.hash
            let updatedSendList = contact.sendList.updatingHash(sendListHash)
            let updatedContact = contact.updatingSendList(updatedSendList)

            // Keep passing the updated contact forward
            return self.model.api.publish(arg: sendListHash,
                                          key: sendAddress.keypairName).then { ($0, updatedContact) }
        }.then { _, contact in
            // Persist the changes only after re-publishing the share list
            self.model.persistentStore.createOrUpdateContact(contact)

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

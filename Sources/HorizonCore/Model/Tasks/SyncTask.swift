//
//  SyncTask.swift
//  HorizonCore
//
//  Created by Connor Power on 23.02.18.
//

import Foundation
import PromiseKit
import IPFSWebService

struct SyncTask: ModelTask {

    // MARK: - Properties

    private let model: Model

    // MARK: - Initializer

    init(model: Model) {
        self.model = model
    }

    // MARK: - Functions

    func sync() -> Promise<[SyncState]> {
        return firstly {
            when(fulfilled: model.contacts.map({ contact -> Promise<(Contact, (String, Data)?)> in
                self.model.eventCallback?(.resolvingReceiveListDidStart(contact))

                guard let receiveAddress = contact.receiveAddress else {
                    return Promise(value: (contact, nil))
                }

                return firstly {
                    self.model.api.resolve(arg: receiveAddress, recursive: true)
                }.then { resolveResponse -> Promise<(Contact, (String, Data)?)> in
                    let receiveListHash = resolveResponse.path
                    return self.model.api.cat(arg: receiveListHash).then { data in
                        // Keep passing the contact forward, along with the new receive list data
                        (contact, (receiveListHash, data))
                    }
                }.recover { _ in
                    Promise(value: (contact, nil))
                }
            }))
        }.then { syncResponses in
            return syncResponses.map { (contact, maybeReceiveListData) in
                guard let receiveListData = maybeReceiveListData else {
                    let error: HorizonError
                    if contact.receiveAddress == nil {
                        error = HorizonError.syncOperationFailed(reason: .receiveAddressNotSet)
                    } else {
                        error = HorizonError.syncOperationFailed(reason: .failedToRetrieveSharedFileList)
                    }

                    return SyncState.failed(contact: contact, error: error)
                }
                let (receiveListHash, data) = receiveListData

                self.model.eventCallback?(.processingReceiveListDidStart(contact))

                if let files = try? JSONDecoder().decode([File].self, from: data) {
                    let updatedContact = contact.updatingReceiveList(FileList(hash: receiveListHash, files: files))

                    self.model.persistentStore.createOrUpdateContact(updatedContact)
                    self.model.eventCallback?(.propertiesDidChange(updatedContact))

                    return SyncState.synced(contact: updatedContact, oldValue: contact)
                } else {
                    let error = HorizonError.syncOperationFailed(reason: .invalidJSONForIPFSObject(receiveListHash))
                    return SyncState.failed(contact: contact, error: error)
                }
            }
        }
    }

}

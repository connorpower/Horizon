//
//  ShareFileTask.swift
//  HorizonCore
//
//  Created by Connor Power on 23.02.18.
//

import Foundation
import PromiseKit
import IPFSWebService

struct ShareFileTask: ModelTask {

    // MARK: - Properties

    private let model: Model

    // MARK: - Initializer

    init(model: Model) {
        self.model = model
    }

    // MARK: - Functions

    func shareFiles(_ files: [URL], with contact: Contact) -> Promise<Contact> {
        for fileName in files.map({ $0.lastPathComponent }) {
            guard model.file(named: fileName, sentOrReceivedFrom: contact) == nil else {
                return Promise(error: HorizonError.fileOperationFailed(reason: .fileAlreadyExists(fileName)))
            }
        }

        // It is ill-advised to check for the presence of a file **before** peforming
        // an operation, but unfortunately the errors we receive from Alamofire are
        // relatively well buried and obtuse, so we peform the sanity checking here.
        // Parsing the AFErrors should probably be encapsulated in a helper extension
        // so we can react to a failure rather than check in advance – as apple suggests.
        for file in files {
            if !FileManager.default.isReadableFile(atPath: file.path) {
                return Promise(error: HorizonError.fileOperationFailed(reason: .fileDoesNotExist(file.path)))
            }
        }

        return firstly {
            when(fulfilled: files.map({ file -> Promise<AddResponse> in
                self.model.eventCallback?(.addingFileToIPFSDidStart(file))
                return self.model.api.add(file: file)
            }))
        }.then { addFileResponses -> Promise<Contact> in
            let newFiles = addFileResponses.map({ return File(name: $0.name, hash: $0.hash) })
            let updatedSendList = FileList(hash: nil, files: Array(Set(contact.sendList.files + newFiles)))
            let updatedContact = contact.updatingSendList(updatedSendList)
            self.model.persistentStore.createOrUpdateContact(updatedContact)

            return PublishFileListTask(model: self.model).publishFileList(for: contact)
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

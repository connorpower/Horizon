//
//  Model.swift
//  HorizonCore
//
//  Created by Jürgen on 02.11.17.
//  Copyright © 2017 Semantical GmbH & Co. KG. All rights reserved.
//

import Foundation
import PromiseKit
import IPFSWebService

public class Model {

    // MARK: - Constants

    struct Constants {
        static let keypairPrefix = "com.semantical.horizon-cli.peer"
    }

    // MARK: - Public Properties

    public var contacts: [Contact] {
        return persistentStore.contacts
    }

    // MARK: - Private Properties

    private let persistentStore = PersistentStore()
    private let api: IPFSAPI

    private let eventCallback: ((Event) -> Void)?

    // [(receiveAddress, Contact)]
    private var syncState = [(receiveHashList: String, contact: Contact)]()

    // MARK: - Initialization

    public init(api: IPFSAPI, eventCallback: ((Event) -> Void)?) {
        self.api = api
        self.eventCallback = eventCallback
    }

    // MARK: - API

    public func sync() {
        guard syncState.isEmpty else { return }

        let newSyncState = persistentStore.contacts.map({ contact -> (receiveHashList: String, contact: Contact)? in
            guard let receiveAddress = contact.receiveAddress else {
                return nil
            }
            return (receiveAddress, contact)
        }).flatMap( {$0} )

        guard !newSyncState.isEmpty else {
            return
        }

        syncState += newSyncState
        eventCallback?(.syncDidStart)

        for (receiveAddress, contact) in syncState {
            eventCallback?(.resolvingReceiveListDidStart(contact))

            firstly {
                return self.api.resolve(arg: receiveAddress, recursive: true)
            }.then { response in
                try self.getFileList(from: contact, at: response.path)
            }.catch { error in
                self.eventCallback?(.errorEvent(HorizonError.syncFailed(reason: .unknown(error))))
            }
        }
    }

    public func addContact(name: String, completion: @escaping (Contact?, HorizonError?) -> Void) {
        let keypairName = "\(Constants.keypairPrefix).\(name)"

        firstly {
            return self.api.listKeys()
        }.then { listKeysResponse  -> Promise<KeygenResponse> in
            if listKeysResponse.keys.map({ $0.name }).contains(keypairName) {
                throw HorizonError.addContactFailed(reason: .contactAlreadyExists)
            }

            self.eventCallback?(.keygenDidStart(name))
            return self.api.keygen(arg: keypairName, type: .rsa, size: 2048)
        }.then { keygenResponse in
            let sendAddress = SendAddress(address: keygenResponse.id, keypairName: keygenResponse.name)
            let contact = Contact(identifier: UUID(), displayName: name,
                                  sendAddress: sendAddress, receiveAddress: nil)

            self.persistentStore.createOrUpdateContact(contact)
            self.eventCallback?(.propertiesDidChange(contact))
            completion(contact, nil)
        }.catch { error in
            let horizonError: HorizonError = error is HorizonError
                ? error as! HorizonError : HorizonError.addContactFailed(reason: .unknown(error))
            self.eventCallback?(.errorEvent(horizonError))
            completion(nil, horizonError)
        }
    }

    public func add(fileURLs: [URL], to contact: Contact) {
        // TODO: Add files in loop using when(fulfilled:) and only upload new fileList when all are added
        for url in fileURLs {
            eventCallback?(.addingFileToIPFSDidStart(File(name: url.lastPathComponent, hash: nil)))

            firstly {
                return self.api.add(file: url)
            }.then { response in
                let newFile = File(name: response.name, hash: response.hash)
                let sendListWithoutDuplicates = Array(Set(contact.sendList.files + [newFile]))
                let sendList = FileList(hash: nil, files: sendListWithoutDuplicates)

                var updatedContact = contact
                updatedContact.sendList = sendList
                self.persistentStore.createOrUpdateContact(updatedContact)

                // WARNING: This will likely fail if multiple concurrent attempts are performed
                // at once. Move commands into a background thread and perform in a blocking
                // synchronious manner
                //
                try self.sendFileList(to: contact)
            }.catch { error in
                self.eventCallback?(.errorEvent(HorizonError.addFileFailed(reason: .unknown(error))))
            }
        }
    }

    // MARK: Private Functions

    private func getFileList(from contact: Contact, at path: String) throws {
        eventCallback?(.downloadingReceiveListDidStart(contact))

        firstly {
            return api.cat(arg: path)
        }.then { data in
            self.eventCallback?(.processingReceiveListDidStart(contact))

            if let files = try? JSONDecoder().decode([File].self, from: data) {
                var updatedContact = contact
                updatedContact.receiveList = FileList(hash: path, files: files)
                self.persistentStore.createOrUpdateContact(updatedContact)

                self.eventCallback?(.propertiesDidChange(contact))
            } else {
                throw HorizonError.retrieveFileListFailed(reason: .invalidJSONAtPath(path))
            }
        }.always {
            self.removeContactFromSyncState(contact)
        }
    }

    private func sendFileList(to contact: Contact) throws {
        guard let data = try? JSONEncoder().encode(contact.sendList.files) else {
            throw HorizonError.sendFileListFailed(reason: .failedToEncodeFileList)
        }

        guard let tempDir = try? FileManager.default.url(for: .itemReplacementDirectory,
                                                         in: .userDomainMask,
                                                         appropriateFor: URL(fileURLWithPath: "/"),
                                                         create: true) else {
            throw HorizonError.sendFileListFailed(reason: .failedToCreateTemporaryDirectory)
        }

        let temporaryFile = tempDir.appendingPathComponent(UUID().uuidString + ".json")
        do {
            try data.write(to: temporaryFile)
        } catch {
            throw HorizonError.sendFileListFailed(reason: .failedToWriteTemporaryFile(temporaryFile))
        }

        eventCallback?(.addingProvidedFileListToIPFSDidStart(contact))

        firstly {
            return api.add(file: temporaryFile)
        }.then { (addFileFesponse: AddResponse) -> Promise<PublishResponse> in
            self.eventCallback?(.publishingFileListToIPNSDidStart(contact))

            return self.api.publish(arg: addFileFesponse.hash, key: contact.sendAddress?.keypairName)
        }.then { (publishResponse: PublishResponse) -> Void in
            var updatedContact = contact
            updatedContact.sendList = FileList(hash: publishResponse.value, files: contact.sendList.files)
            self.persistentStore.createOrUpdateContact(updatedContact)
        }.recover { error -> Void in
            throw HorizonError.sendFileListFailed(reason: .unknown(error))
        }
    }

    private func removeContactFromSyncState(_ contact: Contact) {
        syncState = syncState.filter({ $0.contact.identifier != contact.identifier })

        if syncState.isEmpty {
            eventCallback?(.syncDidEnd)
        }
    }

}

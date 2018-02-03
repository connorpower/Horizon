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

    // [(receiveListHash, Contact)]
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
            guard let receiveListHash = contact.receiveListHash else {
                return nil
            }
            return (receiveListHash, contact)
        }).flatMap( {$0} )

        guard !newSyncState.isEmpty else {
            return
        }

        syncState += newSyncState

        eventCallback?(.syncDidStart)

        for (receiveListHash, contact) in syncState {
            eventCallback?(.resolvingReceiveListDidStart(contact))

            firstly {
                return self.api.resolve(arg: receiveListHash, recursive: true)
            }.then { response in
                self.getFileList(from: contact, at: response.path)
            }.always {
                self.removeContactFromSyncState(contact)
            }.catch { error in
                self.eventCallback?(.syncDidFail(.networkError(error)))
            }
        }
    }

    public func addContact(name: String, completion: @escaping (Contact?) -> Void) {
        let keypairName = "\(Constants.keypairPrefix).\(name)"

        firstly {
            return self.api.listKeys()
        }.then { listKeysResponse  -> Promise<KeygenResponse> in
            if listKeysResponse.keys.map({ $0.name }).contains(keypairName) {
                throw ErrorEvent.keypairAlreadyExists(keypairName)
            }

            self.eventCallback?(.keygenDidStart(name))
            return self.api.keygen(arg: name, type: .rsa, size: 2048)
        }.then { keygenResponse in
            let contact = Contact(identifier: UUID(), displayName: name,
                                  sendListKey: keygenResponse.name, receiveListHash: nil)

            self.persistentStore.createOrUpdateContact(contact)
            self.eventCallback?(.propertiesDidChange(contact))
            completion(contact)
        }.catch { error in
            // Warning: no longer strictly a network error
//            self.eventCallback?(.listKeysDidFail(.networkError(error)))
            completion(nil)
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
                self.sendFileList(to: contact)
            }.catch { error in
                // TODO: Wrong callback
                //self.eventCallback?(.syncDidFail(.networkError(error)))
            }
        }
    }

    // MARK: Private Functions

    private func getFileList(from contact: Contact, at path: String) {
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
                throw ErrorEvent.invalidJSONAtPath(path)
            }
        }.always {
            self.removeContactFromSyncState(contact)
        }.catch { error in
// TODO: Not necessarily a networkError
//            self.eventCallback?(.syncDidFail(.networkError(error)))
        }
    }

    private func sendFileList(to contact: Contact) {
        guard let data = try? JSONEncoder().encode(contact.sendList.files) else {
            eventCallback?(.syncDidFail(.JSONEncodingErrorForContact(contact)))
            removeContactFromSyncState(contact)
            return
        }

        guard let tempDir = try? FileManager.default.url(for: .itemReplacementDirectory,
                                                         in: .userDomainMask,
                                                         appropriateFor: URL(fileURLWithPath: "/"),
                                                         create: true) else {
            fatalError("Failed to create required temp directory.")
        }

        let temporaryFile = tempDir.appendingPathComponent(UUID().uuidString + ".json")
        do {
            try data.write(to: temporaryFile)
        } catch {
            fatalError("Failed to write to temporary file \(temporaryFile).")
        }

        eventCallback?(.addingProvidedFileListToIPFSDidStart(contact))

        firstly {
            return api.add(file: temporaryFile)
        }.then { addFileFesponse -> Promise<PublishResponse> in
            self.eventCallback?(.publishingFileListToIPNSDidStart(contact))

            return self.api.publish(arg: addFileFesponse.hash, key: contact.sendListKey)
        }.then { publishResponse in
            var updatedContact = contact
            updatedContact.sendList = FileList(hash: publishResponse.value, files: contact.sendList.files)
            self.persistentStore.createOrUpdateContact(updatedContact)
        }.always {
            self.removeContactFromSyncState(contact)
        }.catch { error in
//          TODO: Fix
//          self.eventCallback?(.syncDidFail(.networkError(error)))
        }
    }

    private func removeContactFromSyncState(_ contact: Contact) {
        syncState = syncState.filter({ $0.contact.identifier != contact.identifier })

        if syncState.isEmpty {
            eventCallback?(.syncDidEnd)
        }
    }

}

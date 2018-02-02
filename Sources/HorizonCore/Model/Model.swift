//
//  Model.swift
//  HorizonCore
//
//  Created by Jürgen on 02.11.17.
//  Copyright © 2017 Semantical GmbH & Co. KG. All rights reserved.
//

import Foundation

public class Model {

    // MARK: - Public Properties

    public var contacts: [Contact] {
        return persistentStore.contacts
    }

    // MARK: - Private Properties

    private let persistentStore = PersistentStore()
    private let api: IPFSAPI

    private let eventCallback: ((Event) -> Void)?

    private var syncState = [Contact]()

    // MARK: - Initialization

    public init(api: IPFSAPI, eventCallback: ((Event) -> Void)?) {
        self.api = api
        self.eventCallback = eventCallback
    }

    // MARK: - API

    public func sync() {
        guard syncState.isEmpty else { return }

        let contacts = persistentStore.contacts
        guard !contacts.isEmpty else { return }
        syncState += contacts

        eventCallback?(.syncDidStart)

        for contact in syncState {
            eventCallback?(.resolvingReceiveListDidStart(contact))

            if let receiveListHash = contact.receiveListHash {
                self.api.resolve(arg: receiveListHash, recursive: true) { (response, error) in
                    guard let response = response else {
                        self.eventCallback?(.syncDidFail(.networkError(error)))
                        self.removeContactFromSyncState(contact)

                        return
                    }

                    self.getFileList(from: contact, at: response.path)
                }
            } else {
                removeContactFromSyncState(contact)
            }
        }
    }

    public func addContact(contact: Contact) {
        persistentStore.createOrUpdateContact(contact)
        eventCallback?(.propertiesDidChange(contact))
        self.sync()
    }

    public func add(fileURLs: [URL], to contact: Contact) {
        // Warning: a loop here is unsafe. Perform sequentially.
        for url in fileURLs {
            eventCallback?(.addingFileToIPFSDidStart(File(name: url.lastPathComponent, hash: nil)))

            api.add(file: url, completion: { (response, error) in
                guard let response = response else {
                    // Warning: removes contact from sync state, but other URLS might still be adding
                    self.eventCallback?(.syncDidFail(.networkError(error)))
                    self.removeContactFromSyncState(contact)

                    return
                }

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
            })
        }
    }

    public func generateKey(name: String, completion: @escaping ((keypairName: String, hash: String)?) -> Void) {
        eventCallback?(.keygenDidStart(name))

        api.keygen(arg: name, type: .rsa, size: 2048) { (response, error) in
            guard let response = response else {
                self.eventCallback?(.keygenDidFail(.networkError(error)))
                completion(nil)
                return
            }

            completion((keypairName: response.name, hash: response.id))
        }
    }

    public func listKeys(completion: @escaping ([String]?) -> Void) {
        eventCallback?(.listKeysDidStart)

        api.listKeys { (response, error) in
            guard let response = response else {
                self.eventCallback?(.listKeysDidFail(.networkError(error)))
                completion(nil)
                return
            }

            completion(response.keys.map{ $0.name })
        }
    }

    // MARK: Private Functions

    private func getFileList(from contact: Contact, at path: String) {
        eventCallback?(.downloadingReceiveListDidStart(contact))

        api.cat(arg: path) { (data, error) in
            guard let data = data else {
                self.eventCallback?(.syncDidFail(.networkError(error)))
                self.removeContactFromSyncState(contact)

                return
            }

            self.eventCallback?(.processingReceiveListDidStart(contact))

            if let files = try? JSONDecoder().decode([File].self, from: data) {
                var updatedContact = contact
                updatedContact.receiveList = FileList(hash: path, files: files)
                self.persistentStore.createOrUpdateContact(updatedContact)

                self.eventCallback?(.propertiesDidChange(contact))
            } else {
                self.eventCallback?(.syncDidFail(.invalidJSONAtPath(path)))
            }

            self.removeContactFromSyncState(contact)
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
        self.api.add(file: temporaryFile) { (response, error) in
            guard let response = response else {
                self.eventCallback?(.syncDidFail(.networkError(error)))
                self.removeContactFromSyncState(contact)
                return
            }

            self.eventCallback?(.publishingFileListToIPNSDidStart(contact))

            let hash = response.hash
            self.api.publish(arg: hash, key: contact.sendListKey) { (response, error) in
                guard response != nil else {
                    self.eventCallback?(.syncDidFail(.networkError(error)))
                    self.removeContactFromSyncState(contact)
                    return
                }

                var updatedContact = contact
                updatedContact.sendList = FileList(hash: hash, files: contact.sendList.files)
                self.persistentStore.createOrUpdateContact(updatedContact)
            }
        }
    }

    private func removeContactFromSyncState(_ contact: Contact) {
        syncState = syncState.filter({ $0.identifier != contact.identifier })

        if syncState.isEmpty {
            eventCallback?(.syncDidEnd)
        }
    }

}

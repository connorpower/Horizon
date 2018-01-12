//
//  DataModel.swift
//  Horizon
//
//  Created by Jürgen on 02.11.17.
//  Copyright © 2017 Semantical GmbH & Co. KG. All rights reserved.
//

import Foundation

class DataModel {

    // MARK: - Variables

    private let persistentStore = PersistentStore()
    private let api: IPFSAPI

    private var syncState = [Contact]()

    var contacts: [Contact] {
        return persistentStore.contacts
    }

    // MARK: - Initialization

    init(api: IPFSAPI) {
        self.api = api
    }

    // MARK: - API

    func sync() {
        guard syncState.isEmpty else { return }

        let contacts = persistentStore.contacts
        guard !contacts.isEmpty else { return }
        syncState += contacts

        Notifications.broadcastSyncStart()

        for contact in syncState {
            Notifications.broadcastStatusMessage(
                "Interplanetary Naming System: Resolving location of \(contact.displayName)..."
            )
            self.api.resolve(arg: contact.receiveListHash, recursive: true) { (response, error) in
                guard let response = response else {
                    self.handleError(error)
                    return
                }

                self.getFileList(from: contact, at: response.path!)
            }
        }
    }

    func addContact(contact: Contact) {
        persistentStore.createOrUpdateContact(contact)
        Notifications.broadcastNewData()
        self.sync()
    }

    func add(fileURLs: [URL], to contact: Contact) {
        for url in fileURLs {
            Notifications.broadcastStatusMessage("""
                                                 Interplanetary File System: Adding \(url.lastPathComponent)
                                                  for \(contact.displayName)...
                                                 """)
            self.api.add(file: url, completion: { (response, error) in
                guard let response = response else {
                    self.handleError(error)
                    return
                }

                let newFile = File(name: response.name!, hash: response.hash!)
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

    // MARK: Private Functions

    private func getFileList(from contact: Contact, at path: String) {
        Notifications.broadcastStatusMessage(
            "Interplanetary File System: Downloading file list from \(contact.displayName)...")

        api.cat(arg: path) { (data, error) in
            guard let data = data else {
                self.handleError(error)
                return
            }

            Notifications.broadcastStatusMessage(
                "Interplanetary File System: Decoding file list from \(contact.displayName)...")
            if let files = try? JSONDecoder().decode([File].self, from: data) {
                var updatedContact = contact
                updatedContact.receiveList = FileList(hash: path, files: files)
                self.persistentStore.createOrUpdateContact(updatedContact)

                Notifications.broadcastNewData()
            } else {
                print("Failed to decode downloaded JSON\n")
            }

            self.syncState = self.syncState.filter({ $0.displayName != contact.displayName })
            if self.syncState.isEmpty {
                Notifications.broadcastSyncEnd()
            }
        }
    }

    private func sendFileList(to contact: Contact) {
        guard let data = try? JSONEncoder().encode(contact.sendList.files) else {
            Notifications.broadcastStatusMessage("Internal error uploading file list for \(contact.displayName)...")
            return
        }
        guard let tempDir = try? FileManager.default.url(for: .itemReplacementDirectory,
                                                         in: .userDomainMask,
                                                         appropriateFor: URL(fileURLWithPath: "/"),
                                                         create: true) else {
            Notifications.broadcastStatusMessage("Internal error uploading file list for \(contact.displayName)...")
            return

        }

        let temporaryFile = tempDir.appendingPathComponent(UUID().uuidString + ".json")
        do {
            try data.write(to: temporaryFile)
        } catch {
            Notifications.broadcastStatusMessage("Internal error uploading file list for \(contact.displayName)...")
            return
        }

        Notifications.broadcastStatusMessage(
            "Interplanetary File System: Uploading file list for \(contact.displayName)...")
        self.api.add(file: temporaryFile) { (response, error) in
            guard let response = response, let hash = response.hash else {
                self.handleError(error)
                return
            }

            Notifications.broadcastStatusMessage("""
                                                 Interplanetary Naming System: Publishing file list
                                                  for \(contact.displayName)...
                                                 """)
            self.api.publish(arg: hash, key: contact.sendListKey) { (response, error) in
                guard response != nil else {
                    self.handleError(error)
                    return
                }

                var updatedContact = contact
                updatedContact.sendList = FileList(hash: hash, files: contact.sendList.files)
                self.persistentStore.createOrUpdateContact(updatedContact)

                print("Published new file list: \"\(hash)\"")
            }
        }
    }

    private func handleError(_ error: Error?) {
        syncState.removeAll()
        Notifications.broadcastSyncEnd()
    }

}

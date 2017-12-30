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
    private let api: APIProviding

    private var syncState = [Contact]()

    // MARK: - Initialization

    init(api: APIProviding) {
        self.api = api
    }

    // MARK: - API

    func sync() {
        guard syncState.isEmpty else { return }

        syncState += contacts
        Notifications.broadcastSyncStart()

        for contact in contacts {
            Notifications.broadcastStatusMessage("Interplanetary Naming System: Resolving location of \(contact.name)...")
            self.api.resolve(arg: contact.remoteHash, recursive: true) { (response, error) in
                guard let response = response else {
                    self.handleError(error)
                    return
                }

                self.getFileList(from: contact, at: response.path!)
            }
        }
    }

    func addContact(contact: Contact) {
        persistentStore.updateContacts(contacts + [contact])
        Notifications.broadcastNewData()
        self.sync()
    }

    var contacts: [Contact] {
        return persistentStore.contact
    }

    func files(from contact: Contact) -> [File] {
        return persistentStore.receivedFileList(from: contact)
    }

    func files(for contact: Contact) -> [File] {
        return persistentStore.providedFileList(for: contact)
    }

    func add(fileURLs: [URL], to contact: Contact) {
        for url in fileURLs {
            Notifications.broadcastStatusMessage("Interplanetary File System: Adding \(url.lastPathComponent) for \(contact.name)...")
            self.api.add(file: url, completion: { (response, error) in
                guard let response = response else {
                    self.handleError(error)
                    return
                }

                let newFile = File(name: response.name!, hash: response.hash!)
                let providedFiles = self.persistentStore.providedFileList(for: contact) + [newFile]
                let providedFilesWithoutDuplicates = Array(Set(providedFiles))
                self.persistentStore.updateProvidedFileList(providedFilesWithoutDuplicates, for: contact)

                // WARNING: This will likely fail if multiple concurrent attempts are performed
                // at once. Move commands into a background thread and perform in a blocking
                // synchronious manner
                //
                self.publishFileList(providedFilesWithoutDuplicates, to: contact)
            })
        }
    }

    // MARK: Private Functions

    private func getFileList(from contact: Contact, at path: String) {
        Notifications.broadcastStatusMessage("Interplanetary File System: Downloading file list from \(contact.name)...")

        api.cat(arg: path) { (data, error) in
            guard let data = data else {
                self.handleError(error)
                return
            }

            Notifications.broadcastStatusMessage("Interplanetary File System: Decoding file list from \(contact.name)...")
            if let files = try? JSONDecoder().decode([File].self, from: data) {
                self.persistentStore.updateReceivedFileList(files, from: contact)
                Notifications.broadcastNewData()
            } else {
                print("Failed to decode downloaded JSON\n")
            }

            self.syncState = self.syncState.filter({ $0.name != contact.name })
            if self.syncState.isEmpty {
                Notifications.broadcastSyncEnd()
            }
        }
    }

    private func publishFileList(_ fileList: [File], to contact: Contact) {
        // TODO: We should really have an API which simply takes data
        // instead of needing temporary files.
        //
        guard let data = try? JSONEncoder().encode(fileList) else {
            Notifications.broadcastStatusMessage("Internal error uploading file list for \(contact.name)...")
            return
        }
        guard let tempDir = try? FileManager.default.url(for: .itemReplacementDirectory,
                                                         in: .userDomainMask,
                                                         appropriateFor: URL(fileURLWithPath: "/"),
                                                         create: true) else {
            Notifications.broadcastStatusMessage("Internal error uploading file list for \(contact.name)...")
            return

        }

        let temporaryFile = tempDir.appendingPathComponent(UUID().uuidString + ".json")
        do {
            try data.write(to: temporaryFile)
        } catch {
            Notifications.broadcastStatusMessage("Internal error uploading file list for \(contact.name)...")
            return
        }

        Notifications.broadcastStatusMessage("Interplanetary File System: Uploading file list for \(contact.name)...")
        self.api.add(file: temporaryFile) { (response, error) in
            guard let response = response, let hash = response.hash else {
                self.handleError(error)
                return
            }

            Notifications.broadcastStatusMessage("Interplanetary Naming System: Publishing file list for \(contact.name)...")
            self.api.publish(arg: hash, key: contact.name) { (response, error) in
                guard let _ = response else {
                    self.handleError(error)
                    return
                }

                print("Published new file list: \"\(hash)\"")
            }
        }
    }

    private func handleError(_ error: Error?) {
        api.printError(error)
        syncState.removeAll()
        Notifications.broadcastSyncEnd()
    }

}

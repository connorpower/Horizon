//
//  DataModel.swift
//  Horizon
//
//  Created by Jürgen on 02.11.17.
//  Copyright © 2017 Semantical GmbH & Co. KG. All rights reserved.
//

import Foundation

struct DataModel {

    // MARK: - Constants

    struct Notifications {
        static let newDataAvailable = Notification.Name("de.horizon.notification.newDataAvailable")
        static let syncStarted = Notification.Name("de.horizon.notification.syncStarted")
        static let syncEnded = Notification.Name("de.horizon.notification.syncEnded")
    }

    // MARK: - Variables

    private let persistentStore = PersistentStore()
    private let api: APIProviding

    // MARK: - Initialization

    init(api: APIProviding) {
        self.api = api
    }

    // MARK: - API

    func sync() {
        NotificationCenter.default.post(name: Notifications.syncStarted, object: nil)

        for contact in contacts {
            self.api.resolve(arg: contact.remoteHash, recursive: true) { (response, error) in
                guard let response = response else {
                    self.api.printError(error)
                    return
                }

                self.getFileList(from: contact, at: response.path!)
            }
        }
        
        NotificationCenter.default.post(name: Notifications.syncEnded, object: nil)
    }

    func addContact(contact: Contact) {
        persistentStore.updateContacts(contacts + [contact])
        self.broadcastNewData()
        self.sync()
    }

    var contacts: [Contact] {
        return persistentStore.contact
    }

    func files(for contact: Contact) -> [File] {
        return persistentStore.receivedFileList(from: contact)
    }

    func add(fileURLs: [URL], to contact: Contact) {
        for url in fileURLs {
            OperationQueue.main.addOperation {
                self.api.add(file: url, completion: { (response, error) in
                    guard let response = response else {
                        self.api.printError(error)
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
    }

    // MARK: Private Functions

    private func getFileList(from contact: Contact, at path: String) {
        api.cat(arg: path) { (data, error) in
            guard let data = data else {
                self.api.printError(error)
                return
            }

            if let files = try? JSONDecoder().decode([File].self, from: data) {
                self.persistentStore.updateReceivedFileList(files, from: contact)
                self.broadcastNewData()
            } else {
                print("Failed to decode downloaded JSON\n")
            }
        }
    }

    private func publishFileList(_ fileList: [File], to contact: Contact) {
        // TODO: We should really have an API which simply takes data
        // instead of needing temporary files.
        //
        let data = try! JSONEncoder().encode(fileList)
        let tempDir = try! FileManager.default.url(for: .itemReplacementDirectory,
                                                   in: .userDomainMask,
                                                   appropriateFor: URL(fileURLWithPath: "/"),
                                                   create: true)
        let temporaryFile = tempDir.appendingPathComponent(UUID().uuidString + ".json")
        try! data.write(to: temporaryFile)

        self.api.add(file: temporaryFile) { (response, error) in
            guard let response = response, let hash = response.hash else {
                self.api.printError(error)
                return
            }

            self.api.publish(arg: hash, key: contact.name) { (response, error) in
                guard let _ = response else {
                    self.api.printError(error)
                    return
                }

                print("Published new file list: \"\(hash)\"")
            }
        }
    }

    private func broadcastNewData() {
        NotificationCenter.default.post(name: Notifications.newDataAvailable, object: nil)
    }

}

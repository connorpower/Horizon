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
        for contact in contacts {
            self.api.resolve(arg: contact.remoteHash, recursive: true) { (response, error) in
                guard let response = response else {
                    self.api.printError(error)
                    return
                }

                self.getFileList(from: contact, at: response.path!)
            }
        }
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
        var providedFiles = persistentStore.providedFileList(for: contact)

        for file in fileURLs {
            OperationQueue.main.addOperation {
                self.api.add(file: file, completion: { (response, error) in
                    guard let response = response else {
                        self.api.printError(error)
                        return
                    }

                    providedFiles += [File(name: response.name!, hash: response.hash!)]
                })
            }
        }

        OperationQueue.main.addOperation {
            self.persistentStore.updateProvidedFileList(providedFiles, for: contact)

            // TODO: We should really have an API which simply takes data
            // instead of needing temporary files.
            //
            let data = try! JSONEncoder().encode(providedFiles)
            let tempDir = try! FileManager.default.url(for: .itemReplacementDirectory,
                                                       in: .userDomainMask,
                                                       appropriateFor: URL(fileURLWithPath: "/"),
                                                       create: true)
            let temporaryFile = tempDir.appendingPathComponent(UUID().uuidString + ".json")
            try! data.write(to: temporaryFile)

            self.api.add(file: temporaryFile) { (response, error) in
                guard let response = response else {
                    self.api.printError(error)
                    return
                }

                self.publishFileList(response.hash!, to: contact)
            }
        }
    }

    // MARK: Private Functions

    private func getFileList(from contact: Contact, at path: String) {
        api.get(arg: path) { (data, error) in
            guard let data = data else {
                self.api.printError(error)
                return
            }

            if let files = try? JSONDecoder().decode([File].self, from: data) {
                self.persistentStore.updateReceivedFileList(files, from: contact)
                self.broadcastNewData()
            } else {
                print("Failed to decode downloaded JSON")
            }
        }
    }

    private func publishFileList(_ hash: String, to contact: Contact) {
        OperationQueue.main.addOperation {
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

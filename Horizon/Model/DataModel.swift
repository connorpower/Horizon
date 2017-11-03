//
//  DataModel.swift
//  Horizon
//
//  Created by Jürgen on 02.11.17.
//  Copyright © 2017 Semantical GmbH & Co. KG. All rights reserved.
//

import Foundation

struct DataModel {

    // MARK: - Variables

    private let persistentStore = PersistentStore()
    private let api: APIProviding

    var contacts: [Contact] = []

    // MARK: - Initialization

    init(api: APIProviding) {
        self.api = api

        contacts = [
            Contact(name: "Connor", senderId: "", receiverId: ""),
            Contact(name: "Steffen", senderId: "", receiverId: ""),
        ]
    }

    // MARK: - API

    func sync() {

    }

    func files(for contact: Contact) -> [File] {
        return persistentStore.receivedFileList(from: contact)
    }

    func add(fileURLs: [URL], to contact: Contact) {
        var providedFiles = persistentStore.providedFileList(for: contact)

        for file in fileURLs {
            OperationQueue.main.addOperation {
                self.api.add(file: file, completion: { (response, error) in
                    guard let response = response else { fatalError("\(error!.localizedDescription)") }

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
                guard let response = response else { fatalError("\(error!.localizedDescription)") }

                self.publishFileList(response.hash!, to: contact)
            }
        }
    }

    private func publishFileList(_ hash: String, to contact: Contact) {
        OperationQueue.main.addOperation {
            // TODO: use the Contact's key instead of "self"
            //
            self.api.publish(arg: hash, key: "self") { (response, error) in
                guard let _ = response else { fatalError("\(error!.localizedDescription)") }

                print("Published new file list: \"\(hash)\"")
            }
        }
    }

}

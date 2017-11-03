//
//  PersistentStore.swift
//  Horizon
//
//  Created by Connor Power on 03.11.17.
//  Copyright © 2017 Semantical GmbH & Co. KG. All rights reserved.
//

import Foundation

fileprivate struct UserDefaultsKeys {
    static let providedFileList = "de.horizon.providedFileList"
    static let receivedFileList = "de.horizon.receivedFileList"
}

struct PersistentStore {

    // MARK: - Functions

    func receivedFileList(from contact: Contact) -> [File] {
//        if let jsonData = UserDefaults.standard.data(forKey: contact.receivedFileListKey) {
//            let files = try? JSONDecoder().decode([File].self, from: jsonData)
//            return files ?? [File]()
//        } else {
//            return [File]()
//        }
        if contact.name == "Connor" {
            return [File(name: "1", hash: nil), File(name: "2", hash: nil), File(name: "3", hash: nil)]
        }
        else {
            return [File(name: "a", hash: nil), File(name: "b", hash: nil), File(name: "c", hash: nil)]
        }
    }

    func providedFileList(for contact: Contact) -> [File] {
        if let jsonData = UserDefaults.standard.data(forKey: contact.providedFileListKey) {
            let files = try? JSONDecoder().decode([File].self, from: jsonData)
            return files ?? [File]()
        } else {
            return [File]()
        }
    }

    func updateProvidedFileList(_ fileList: [File], for contact: Contact) {
        let jsonData = try! JSONEncoder().encode(fileList)
        UserDefaults.standard.set(jsonData, forKey: contact.providedFileListKey)
    }

}

fileprivate extension Contact {

    var providedFileListKey: String {
        return UserDefaultsKeys.providedFileList + ".\(name)"
    }

    var receivedFileListKey: String {
        return UserDefaultsKeys.receivedFileList + ".\(name)"
    }

}

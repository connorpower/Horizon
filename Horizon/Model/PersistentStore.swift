//
//  PersistentStore.swift
//  Horizon
//
//  Created by Connor Power on 03.11.17.
//  Copyright © 2017 Semantical GmbH & Co. KG. All rights reserved.
//

import Foundation

fileprivate struct UserDefaultsKeys {
    static let providedFileListBase = "de.horizon.providedFileList"
}

struct PersistentStore {

    // MARK: - Functions

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
        return UserDefaultsKeys.providedFileListBase + ".\(name)"
    }

}

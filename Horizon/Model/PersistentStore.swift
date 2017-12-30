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
    static let contactList = "de.horizon.contactList"
}

struct PersistentStore {

    // MARK: - Functions

    var contact: [Contact] {
        if let jsonData = UserDefaults.standard.data(forKey: UserDefaultsKeys.contactList) {
            let contacts = try? JSONDecoder().decode([Contact].self, from: jsonData)
            return contacts ?? [Contact]()
        } else {
            return [Contact]()
        }
    }

    func updateContacts(_ contacts: [Contact]) {
        guard let jsonData = try? JSONEncoder().encode(contacts) else {
            Notifications.broadcastStatusMessage("Internal error updating contacts list...")
            return
        }
        UserDefaults.standard.set(jsonData, forKey: UserDefaultsKeys.contactList)
    }

    func receivedFileList(from contact: Contact) -> [File] {
        if let jsonData = UserDefaults.standard.data(forKey: contact.receivedFileListKey) {
            let files = try? JSONDecoder().decode([File].self, from: jsonData)
            return files ?? [File]()
        } else {
            return [File]()
        }
    }

    func updateReceivedFileList(_ fileList: [File], from contact: Contact) {
        guard let jsonData = try? JSONEncoder().encode(fileList) else {
            Notifications.broadcastStatusMessage("Internal error updating received file list from \(contact.name)...")
            return
        }
        UserDefaults.standard.set(jsonData, forKey: contact.receivedFileListKey)
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
        guard let jsonData = try? JSONEncoder().encode(fileList) else {
            Notifications.broadcastStatusMessage("Internal error updating shared file list for \(contact.name)...")
            return
        }
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

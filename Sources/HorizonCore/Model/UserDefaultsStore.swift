//
//  UserDefaultsStore.swift
//  HorizonCore
//
//  Created by Connor Power on 03.11.17.
//  Copyright © 2017 Semantical GmbH & Co. KG. All rights reserved.
//

import Foundation

/**
 The `UserDefaultsStore` acts a simple abstraction between the
 model and persistence technology du jour.
 */
public struct UserDefaultsStore: PersistentStore {

    // MARK: - Properties

    private let configuration: Configuration

    // MARK: - Initialization

    public init(configuration: Configuration) {
        self.configuration = configuration
    }

    // MARK: - Functions

    /**
     Returns the array of all contacts which whom data is
     shared.
     */
    public var contacts: [Contact] {
        if let jsonString = UserDefaults.standard.string(forKey: configuration.persistentStoreKeys.contactList),
            let jsonData = jsonString.data(using: .utf8) {
            let contacts = try? JSONDecoder().decode([Contact].self, from: jsonData)
            return contacts ?? [Contact]()
        } else {
            return [Contact]()
        }
    }

    /**
     A simple function which either creates a new contact
     in the persistent store, or updates a contact with the
     same identifier.

     - parameter contact: The contact to write to the persistent
       store.
     */
    public func createOrUpdateContact(_ contact: Contact) {
        let newContacts = contacts.filter({ $0.identifier != contact.identifier }) + [contact]

        guard let jsonData = try? JSONEncoder().encode(newContacts) else {
            fatalError("JSON Encoding failure. Failed to save new contacts list.")
        }

        let jsonString = String(bytes: jsonData, encoding: .utf8)
        UserDefaults.standard.set(jsonString, forKey: configuration.persistentStoreKeys.contactList)
    }

    /**
     Removes a contact from the store.

     - parameter contact: The contact to remove from the persistent
     store.
     */
    public func removeContact(_ contact: Contact) {
        let newContacts = contacts.filter({ $0.identifier != contact.identifier })

        guard let jsonData = try? JSONEncoder().encode(newContacts) else {
            fatalError("JSON Encoding failure. Failed to save new contacts list.")
        }

        let jsonString = String(bytes: jsonData, encoding: .utf8)
        UserDefaults.standard.set(jsonString, forKey: configuration.persistentStoreKeys.contactList)
    }

}

//
//  PersistentStore.swift
//  HorizonCore
//
//  Created by Connor Power on 03.11.17.
//  Copyright © 2017 Semantical GmbH & Co. KG. All rights reserved.
//

import Foundation

/**
 The persistent store acts a simple abstraction between the
 model and persistence technology du jour.
 */
public struct PersistentStore {

    // MARK: - Constants

    private struct UserDefaultsKeys {

        /**
         The NSUserDefaults key for the list of contacts.
         */
        static let contactList = "com.semantical.Horizon.contactList"
    }

    // MARK: - Functions

    /**
     Returns the array of all contacts which whom data is
     shared.
     */
    public var contacts: [Contact] {
        if let jsonData = UserDefaults.standard.data(forKey: UserDefaultsKeys.contactList) {
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
        UserDefaults.standard.set(jsonData, forKey: UserDefaultsKeys.contactList)
    }

}

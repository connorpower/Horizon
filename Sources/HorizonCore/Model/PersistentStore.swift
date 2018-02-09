//
//  PersistentStore.swift
//  HorizonCore
//
//  Created by Connor Power on 09.02.18.
//

import Foundation

/**
 The `PersistentStore` groups the various kinds of persistent stores
 (including mocks for unit testing) under a single protocol.
 */
public protocol PersistentStore {

    /**
     Returns the array of all contacts which whom data is shared.
     */
    var contacts: [Contact] { get }

    /**
     A simple function which either creates a new contact
     in the persistent store, or updates a contact with the
     same identifier.

     - parameter contact: The contact to write to the persistent
     store.
     */
    func createOrUpdateContact(_ contact: Contact)

    /**
     Removes a contact from the store.

     - parameter contact: The contact to remove from the persistent
     store.
     */
    func removeContact(_ contact: Contact)

}

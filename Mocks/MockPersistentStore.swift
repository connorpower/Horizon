//
//  MockPersistentStore.swift
//  HorizonCoreTests
//
//  Created by Connor Power on 09.02.18.
//

import Foundation
@testable import HorizonCore

class MockPersistentStore: PersistentStore {

    var contacts = [Contact]()

    var createOrUpdateContactHook: (() -> Void)?
    var removeContactHook: (() -> Void)?

    func createOrUpdateContact(_ contact: Contact) {
        createOrUpdateContactHook?()
        contacts = contacts.filter({ $0.identifier != contact.identifier }) + [contact]
    }

    func removeContact(_ contact: Contact) {
        removeContactHook?()
        contacts = contacts.filter({ $0.identifier != contact.identifier })
    }

}

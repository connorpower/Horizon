//
//  MockPersistentStore.swift
//  HorizonCoreTests
//
//  Created by Connor Power on 09.02.18.
//  Copyright © 2018 Connor Power. All rights reserved.
//

import Foundation
@testable import HorizonCore

class MockPersistentStore: PersistentStore {

    var contacts = [Contact]()

    var createOrUpdateContactHook: ((Contact) -> Void)?
    var removeContactHook: ((Contact) -> Void)?

    func createOrUpdateContact(_ contact: Contact) {
        createOrUpdateContactHook?(contact)
        contacts = contacts.filter({ $0.identifier != contact.identifier }) + [contact]
    }

    func removeContact(_ contact: Contact) {
        removeContactHook?(contact)
        contacts = contacts.filter({ $0.identifier != contact.identifier })
    }

}

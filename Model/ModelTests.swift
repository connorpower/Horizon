//
//  ModelTests.swift
//  HorizonCoreTests
//
//  Created by Connor Power on 09.02.18.
//  Copyright © 2018 Semantical GmbH & Co. KG. All rights reserved.
//

import XCTest
@testable import HorizonCore

class ModelTests: XCTestCase {

    var mockAPI: MockIPFSAPI!
    var mockStore: MockPersistentStore!
    
    override func setUp() {
        super.setUp()
        mockAPI = MockIPFSAPI()
        mockStore = MockPersistentStore()
    }
    
    override func tearDown() {
        mockAPI = nil
        mockStore = nil
        super.tearDown()
    }
    
    func testInitialization() {
        let model = Model(api: mockAPI, persistentStore: mockStore, eventCallback: nil)
        XCTAssertNotNil(model)
    }

    func testContacts() {
        let contact1 = Contact(identifier: UUID(), displayName: "Contact1", sendAddress: nil, receiveAddress: nil)
        let contact2 = Contact(identifier: UUID(), displayName: "Contact2", sendAddress: nil, receiveAddress: nil)
        mockStore.contacts = [contact1, contact2]
        let model = Model(api: mockAPI, persistentStore: mockStore, eventCallback: nil)

        XCTAssertEqual(2, model.contacts.count)
        XCTAssertTrue(model.contacts.contains(contact1))
        XCTAssertTrue(model.contacts.contains(contact2))
    }

    func testContactNamed() {
        let contact1 = Contact(identifier: UUID(), displayName: "Foo1", sendAddress: nil, receiveAddress: nil)
        let contact2 = Contact(identifier: UUID(), displayName: "2Foo", sendAddress: nil, receiveAddress: nil)
        let contact3 = Contact(identifier: UUID(), displayName: "Foo Fighters", sendAddress: nil, receiveAddress: nil)
        let contact4 = Contact(identifier: UUID(), displayName: "Foo", sendAddress: nil, receiveAddress: nil)

        mockStore.contacts = [contact1, contact2, contact3, contact4]
        let model = Model(api: mockAPI, persistentStore: mockStore, eventCallback: nil)

        let foundContact = model.contact(named: "Foo")
        XCTAssertNotNil(foundContact)
        XCTAssertEqual(foundContact?.identifier, contact4.identifier)
    }

    func testUpdateReceiveAddressForContact() {
        let contact1 = Contact(identifier: UUID(), displayName: "Contact1", sendAddress: nil, receiveAddress: nil)
        let contact2 = Contact(identifier: UUID(), displayName: "Contact2", sendAddress: nil, receiveAddress: nil)
        mockStore.contacts = [contact1, contact2]
        let model = Model(api: mockAPI, persistentStore: mockStore, eventCallback: nil)

        model.updateReceiveAddress(for: contact2, to: "28EA684E-FF5C-4793-8B8D-66C68527E62F")

        let foundContact = model.contact(named: "Contact2")
        XCTAssertNotNil(foundContact)
        XCTAssertEqual(foundContact?.receiveAddress, "28EA684E-FF5C-4793-8B8D-66C68527E62F")
        XCTAssertEqual(model.contacts.count, 2)
        XCTAssertTrue(model.contacts.contains(contact1))
    }

}

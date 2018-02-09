//
//  ModelTests.swift
//  HorizonCoreTests
//
//  Created by Connor Power on 09.02.18.
//  Copyright © 2018 Semantical GmbH & Co. KG. All rights reserved.
//

import XCTest
import IPFSWebService
import PromiseKit
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

    /**
     Expect that adding a contact under normal circumstances succeeds.
     */
    func testAddContact_NoPreviousContact() {
        let contact1 = Contact(identifier: UUID(), displayName: "Contact1", sendAddress: nil, receiveAddress: nil)
        mockStore.contacts = [contact1]
        let model = Model(api: mockAPI, persistentStore: mockStore, eventCallback: nil)

        let contactPersistedExpectation = expectation(description: "contactPersistedExpectation")
        let contactAddedExpectation = expectation(description: "contactAddedExpectation")

        mockAPI.listKeysResponse = { ListKeysResponse(keys: [Key]()) }
        mockAPI.keygenResponse = { KeygenResponse(name: "My Key", id: "My Key ID") }
        mockStore.createOrUpdateContactHook = { contact in
            XCTAssertEqual(contact.displayName, "Added Contact Display Name")
            contactPersistedExpectation.fulfill()
        }

        firstly {
            model.addContact(name: "Added Contact Display Name")
        }.then { contact in
            XCTAssertEqual(contact.displayName, "Added Contact Display Name")
            XCTAssertNotNil(model.contact(named: "Added Contact Display Name"))
            contactAddedExpectation.fulfill()
        }

        wait(for: [contactPersistedExpectation, contactAddedExpectation], timeout: 1.0)
    }

    /**
     Expect that an attempt to add a contact with the same name as an
     exiting contact fails. The presense of a key in IPFS need not be taken
     into consideration.
     */
    func testAddContact_PreExistingContact_MissingKey() {
        let contact1 = Contact(identifier: UUID(), displayName: "Contact1", sendAddress: nil, receiveAddress: nil)
        mockStore.contacts = [contact1]
        let model = Model(api: mockAPI, persistentStore: mockStore, eventCallback: nil)

        let contactAddedExpectation = expectation(description: "contactAddedExpectation")

        mockAPI.listKeysResponse = { ListKeysResponse(keys: [Key]()) }
        mockAPI.keygenResponse = { KeygenResponse(name: "XXX", id: "XXX") }

        firstly {
            model.addContact(name: "Contact1")
        }.then { _ in
            XCTFail("Should have thrown a duplicate contact error")
            contactAddedExpectation.fulfill()
        }.catch { error in
            if case HorizonError.contactOperationFailed(let reason) = error {
                if case .contactAlreadyExists = reason {
                    XCTAssertTrue(true)
                } else {
                    XCTFail()
                }
            } else {
                XCTFail()
            }
            contactAddedExpectation.fulfill()
        }

        wait(for: [contactAddedExpectation], timeout: 1.0)
    }

    /**
     Expect that an attempt to add a contact fails if an orphaned key exists in IPFS.
     */
    func testAddContact_MissingContact_PreExistingKey() {
        mockStore.contacts = []
        let model = Model(api: mockAPI, persistentStore: mockStore, eventCallback: nil)

        let contactAddedExpectation = expectation(description: "contactAddedExpectation")

        mockAPI.listKeysResponse = {
            ListKeysResponse(keys: [Key(name: "\(Model.Constants.keypairPrefix).Contact1", id: "XXXX")])
        }
        mockAPI.keygenResponse = {
            KeygenResponse(name: "XXX", id: "XXX")
        }

        firstly {
            model.addContact(name: "Contact1")
        }.then { _ in
            XCTFail("Should have thrown a duplicate contact error")
            contactAddedExpectation.fulfill()
        }.catch { error in
            if case HorizonError.contactOperationFailed(let reason) = error {
                if case .contactAlreadyExists = reason {
                    XCTAssertTrue(true)
                } else {
                    XCTFail()
                }
            } else {
                XCTFail()
            }
            contactAddedExpectation.fulfill()
        }

        wait(for: [contactAddedExpectation], timeout: 1.0)
    }

    /**
     Expect that removing a contact under normal circumstances succeeds.
     */
    func testRemoveContact() {
        let contact1 = Contact(identifier: UUID(), displayName: "Contact1", sendAddress: nil, receiveAddress: nil)
        mockStore.contacts = [contact1]
        let model = Model(api: mockAPI, persistentStore: mockStore, eventCallback: nil)

        let contactUnpersistedExpectation = expectation(description: "contactUnpersistedExpectation")
        let contactRemovedExpectation = expectation(description: "contactRemovedExpectation")

        mockAPI.listKeysResponse = {
            ListKeysResponse(keys: [Key(name: "\(Model.Constants.keypairPrefix).Contact1", id: "XXXX")])
        }
        mockAPI.removeKeyResponse = { RemoveKeyResponse(keys: [Key]()) }
        mockStore.removeContactHook = { contact in
            XCTAssertEqual(contact.displayName, "Contact1")
            contactUnpersistedExpectation.fulfill()
        }

        firstly {
            model.removeContact(name: "Contact1")
        }.then {
            contactRemovedExpectation.fulfill()
        }

        wait(for: [contactUnpersistedExpectation, contactRemovedExpectation], timeout: 1.0)
    }

    /**
     Expect that an attempt to remove an existing contact succeeds if the
     underlying key in IPFS is missing.
     */
    func testRemoveContact_PreExistingContact_MissingKey() {
        let contact1 = Contact(identifier: UUID(), displayName: "Contact1", sendAddress: nil, receiveAddress: nil)
        mockStore.contacts = [contact1]
        let model = Model(api: mockAPI, persistentStore: mockStore, eventCallback: nil)

        let contactUnpersistedExpectation = expectation(description: "contactUnpersistedExpectation")
        let contactRemovedExpectation = expectation(description: "contactRemovedExpectation")

        mockAPI.listKeysResponse = { ListKeysResponse(keys: [Key]()) }
        mockAPI.removeKeyResponse = { RemoveKeyResponse(keys: [Key]()) }
        mockStore.removeContactHook = { contact in
            XCTAssertEqual(contact.displayName, "Contact1")
            contactUnpersistedExpectation.fulfill()
        }

        firstly {
            model.removeContact(name: "Contact1")
        }.then {
            contactRemovedExpectation.fulfill()
        }

        wait(for: [contactUnpersistedExpectation, contactRemovedExpectation], timeout: 1.0)
    }

    /**
     Expect that an attempt to remove a contact succeeds if there was an orphaned
     key in IPFS, regardless of whether there was a contact in Horizon.
     */
    func testRemoveContact_MissingContact_PreExistingKey() {
        mockStore.contacts = []
        let model = Model(api: mockAPI, persistentStore: mockStore, eventCallback: nil)

        let keyRemovedExpectation = expectation(description: "keyRemovedExpectation")
        let contactRemovedExpectation = expectation(description: "contactRemovedExpectation")

        mockAPI.listKeysResponse = {
            ListKeysResponse(keys: [Key(name: "\(Model.Constants.keypairPrefix).Contact1", id: "XXXX")])
        }
        mockAPI.removeKeyResponse = {
            keyRemovedExpectation.fulfill()
            return RemoveKeyResponse(keys: [Key]())
        }
        mockStore.removeContactHook = { _ in }

        firstly {
            model.removeContact(name: "Contact1")
        }.then {
            contactRemovedExpectation.fulfill()
        }

        wait(for: [keyRemovedExpectation, contactRemovedExpectation], timeout: 1.0)
    }

}

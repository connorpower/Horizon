//
//  ModelTests_Sync.swift
//  HorizonCoreTests
//
//  Created by Connor Power on 17.02.18.
//  Copyright © 2018 Semantical GmbH & Co. KG. All rights reserved.
//

import XCTest
import IPFSWebService
import PromiseKit
@testable import HorizonCore

class ModelTests_Sync: XCTestCase {

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

    /**
     Expect that syncing first resolves a file list and then retrieves the
     resolved file list, and finally updates the hash associated with
     the file list to point to the resolved list.
     */
    func testSync_ResolvesFileList() {
        let contact1 = Contact(identifier: UUID(), displayName: "Contact1",
                               sendAddress: SendAddress(address: "7A5055A5-39A7-4CE4-8061-7C80F918229A",
                                                        keypairName: "my.keypair.name"),
                               receiveAddress: "XX-MY-RECEIVE-ADDRESS-XX")
        mockStore.contacts = [contact1]
        let model = Model(api: mockAPI, config: MockConfiguration(), persistentStore: mockStore, eventCallback: nil)

        let resolveReceiveListExpectation = expectation(description: "resolveReceiveListExpectation")
        let catReceiveListExpectation = expectation(description: "catReceiveListExpectation")
        let syncCompletedExpectation = expectation(description: "syncCompletedExpectation")

        mockAPI.resolveResponse = { ipnsHash, recursive in
            resolveReceiveListExpectation.fulfill()
            XCTAssertEqual("XX-MY-RECEIVE-ADDRESS-XX", ipnsHash,
                           "An attempt was made to resolve an unrelated hash.")
            XCTAssertEqual(true, recursive,
                           "Resolving should be performed recursively")

            return Promise(value: ResolveResponse(path: "XX-MY-RESOLVED-IPFS-ADDRESS-XX"))
        }
        mockAPI.catResponse = { hash in
            catReceiveListExpectation.fulfill()
            XCTAssertEqual("XX-MY-RESOLVED-IPFS-ADDRESS-XX", hash,
                           "The cat operation should have been perfomed on the newly resolved IPNS hash")

            let data = """
            [{"name": "My File Name", "hash": "EFGH"}]
            """.data(using: .utf8)!

            return Promise(value: data)
        }

        firstly {
            model.sync()
        }.then { contacts in
            XCTAssertEqual(1,contacts.count)

            let contact = contacts[0]
            XCTAssertEqual("XX-MY-RESOLVED-IPFS-ADDRESS-XX", contact.receiveList.hash,
                           "The receive list's hash should be updated after being resolved to a new file.")
            syncCompletedExpectation.fulfill()
        }.catch { error in
            XCTFail("Sync operation should not have failed")
            syncCompletedExpectation.fulfill()
        }

        wait(for: [resolveReceiveListExpectation, catReceiveListExpectation, syncCompletedExpectation], timeout: 1.0)
    }

    /**
     Expect that syncing updates a contact's file list.
     */
    func testSync_UpdatesFileList() {
        let contact1 = Contact(identifier: UUID(), displayName: "Contact1",
                               sendAddress: SendAddress(address: "7A5055A5-39A7-4CE4-8061-7C80F918229A",
                                                        keypairName: "my.keypair.name"),
                               receiveAddress: "XX-MY-RECEIVE-ADDRESS-XX")
        mockStore.contacts = [contact1]
        let model = Model(api: mockAPI, config: MockConfiguration(), persistentStore: mockStore, eventCallback: nil)

        let syncCompletedExpectation = expectation(description: "syncCompletedExpectation")

        mockAPI.resolveResponse = { _, _ in
            return Promise(value: ResolveResponse(path: "XX-MY-RESOLVED-IPFS-ADDRESS-XX"))
        }
        mockAPI.catResponse = { _ in
            return Promise(value: "[{\"name\": \"My File Name\", \"hash\": \"EFGH\"}]".data(using: .utf8)!)
        }

        firstly {
            model.sync()
        }.then { contacts in
            XCTAssertEqual(1,contacts.count)

            let contact = contacts[0]
            XCTAssertEqual(1, contact.receiveList.files.count)
            XCTAssertEqual("My File Name", contact.receiveList.files[0].name)
            XCTAssertEqual("EFGH", contact.receiveList.files[0].hash)
            syncCompletedExpectation.fulfill()
        }.catch { error in
            XCTFail("Sync operation should not have failed")
            syncCompletedExpectation.fulfill()
        }

        wait(for: [syncCompletedExpectation], timeout: 1.0)
    }

    /**
     Expect that syncing completes, even when there are no contacts.
     */
    func testSync_NoContacts() {
        mockStore.contacts = []
        let model = Model(api: mockAPI, config: MockConfiguration(), persistentStore: mockStore, eventCallback: nil)

        let syncCompletedExpectation = expectation(description: "syncCompletedExpectation")

        firstly {
            model.sync()
        }.then { contacts in
            XCTAssertEqual(0, contacts.count)
            syncCompletedExpectation.fulfill()
        }.catch { error in
            XCTFail("Sync operation should not have failed")
            syncCompletedExpectation.fulfill()
        }

        wait(for: [syncCompletedExpectation], timeout: 1.0)
    }


    /**
     Expect that syncing completes, even when all contacts are missing their
     receive addresses.
     */
    func testSync_MissingReceiveAddress() {
        let contact1 = Contact(identifier: UUID(), displayName: "Contact1",
                               sendAddress: SendAddress(address: "7A5055A5-39A7-4CE4-8061-7C80F918229A",
                                                        keypairName: "my.keypair.name"), receiveAddress: nil)
        mockStore.contacts = [contact1]
        let model = Model(api: mockAPI, config: MockConfiguration(), persistentStore: mockStore, eventCallback: nil)

        let syncCompletedExpectation = expectation(description: "syncCompletedExpectation")

        firstly {
            model.sync()
        }.then { contacts in
            XCTAssertEqual(1,contacts.count)
            let contact = contacts[0]
            XCTAssertEqual(0, contact.receiveList.files.count)
            syncCompletedExpectation.fulfill()
        }.catch { error in
            XCTFail("Sync operation should not have failed")
            syncCompletedExpectation.fulfill()
        }

        wait(for: [syncCompletedExpectation], timeout: 1.0)
    }


    /**
     Expect that invalid JSON throws an error
     */
    func testSync_InvalidJSON() {
        let contact1 = Contact(identifier: UUID(), displayName: "Contact1",
                               sendAddress: SendAddress(address: "7A5055A5-39A7-4CE4-8061-7C80F918229A",
                                                        keypairName: "my.keypair.name"),
                               receiveAddress: "XX-MY-RECEIVE-ADDRESS-XX")
        mockStore.contacts = [contact1]
        let model = Model(api: mockAPI, config: MockConfiguration(), persistentStore: mockStore, eventCallback: nil)

        let syncCompletedExpectation = expectation(description: "syncCompletedExpectation")

        mockAPI.resolveResponse = { ipnsHash, recursive in
            return Promise(value: ResolveResponse(path: "XX-MY-RESOLVED-IPFS-ADDRESS-XX"))
        }
        mockAPI.catResponse = { hash in
            let data = """
            [I am": "INCALID", JSON: EFGH"}]
            """.data(using: .utf8)!

            return Promise(value: data)
        }

        firstly {
            model.sync()
        }.then { contacts in
            XCTFail("Sync shouldnot have completed without throwing an error")
            syncCompletedExpectation.fulfill()
        }.catch { error in
            if case HorizonError.syncOperationFailed(let reason) = error {
                if case HorizonError.SyncOperationFailureReason.invalidJSONForIPFSObject(let ipfsHash) = reason {
                    XCTAssertEqual( "XX-MY-RESOLVED-IPFS-ADDRESS-XX", ipfsHash)
                } else {
                    XCTFail("Incorrect error type received")
                }
            } else {
                XCTFail("Incorrect error type received")
            }
            syncCompletedExpectation.fulfill()
        }

        wait(for: [syncCompletedExpectation], timeout: 1.0)
    }
    
}

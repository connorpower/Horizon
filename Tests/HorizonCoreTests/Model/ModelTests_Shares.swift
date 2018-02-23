//
//  ModelTests_Shares.swift
//  HorizonCoreTests
//
//  Created by Connor Power on 10.02.18.
//  Copyright © 2018 Semantical GmbH & Co. KG. All rights reserved.
//

import XCTest
import IPFSWebService
import PromiseKit
@testable import HorizonCore

class ModelTests_Shares: XCTestCase {

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
     Expect that adding a share under normal circumstances succeeds.
     */
    func testAddShare_NormalCircumstances() {
        let contact1 = Contact(identifier: UUID(), displayName: "Contact1",
                               sendAddress: SendAddress(address: "7A5055A5-39A7-4CE4-8061-7C80F918229A",
                                                        keypairName: "my.keypair.name"), receiveAddress: nil)
        mockStore.contacts = [contact1]
        let model = Model(api: mockAPI,
                          configuration: MockConfiguration(),
                          persistentStore: mockStore,
                          eventCallback: nil)

        let shareAddedExpectation = expectation(description: "shareAddedExpectation")

        mockAPI.addResponse = { url in
            Promise(value: AddResponse(name: url.lastPathComponent, hash: UUID().uuidString, size: "12345"))
        }
        mockAPI.publishResponse = { hash, keypair in
            Promise(value: PublishResponse(name: keypair!, value: UUID().uuidString))
        }

        firstly {
            model.shareFiles([Bundle.main.executableURL!], with: contact1)
        }.then { contact in
            XCTAssertEqual(1, contact.sendList.files.count)
            XCTAssertEqual("xctest", contact.sendList.files.first?.name)
            XCTAssertNotNil(contact.sendList.hash)
            shareAddedExpectation.fulfill()
        }

        wait(for: [shareAddedExpectation], timeout: 1.0)
    }

    /**
     Expect that an attempt to share a file with a contact fails if the
     contact does not have a send address set.
     */
    func testAddShare_MissingSendAddressKey() {
        let contact1 = Contact(identifier: UUID(), displayName: "Contact1",
                               sendAddress: nil, receiveAddress: nil)
        mockStore.contacts = [contact1]
        let model = Model(api: mockAPI, configuration: MockConfiguration(), persistentStore: mockStore, eventCallback: nil)

        let errorThrownExpectation = expectation(description: "errorThrownExpectation")

        firstly {
            model.shareFiles([Bundle.main.executableURL!], with: contact1)
        }.then { contact in
            XCTFail("Should have thrown an error")
        }.catch { error in
            if case HorizonError.fileOperationFailed(let reason) = error {
                if case .sendAddressNotSet = reason {
                    XCTAssertTrue(true)
                } else {
                    XCTFail()
                }
            } else {
                XCTFail()
            }
            errorThrownExpectation.fulfill()
        }

        wait(for: [errorThrownExpectation], timeout: 1.0)
    }

    /**
     Expect that an attempt to share a file fails if the file is not
     accessable.
     */
    func testAddShare_FileNotFound() {
        let contact1 = Contact(identifier: UUID(), displayName: "Contact1",
                               sendAddress: SendAddress(address: "7A5055A5-39A7-4CE4-8061-7C80F918229A",
                                                        keypairName: "my.keypair.name"), receiveAddress: nil)
        mockStore.contacts = [contact1]
        let model = Model(api: mockAPI,
                          configuration: MockConfiguration(),
                          persistentStore: mockStore,
                          eventCallback: nil)

        let errorThrownExpectation = expectation(description: "errorThrownExpectation")

        firstly {
            model.shareFiles([URL(string: "file:///Im/a/teapot.xyz")!], with: contact1)
        }.then { contact in
            XCTFail("Should have thrown an error")
        }.catch { error in
            if case HorizonError.fileOperationFailed(let reason) = error {
                if case .fileDoesNotExist = reason {
                    XCTAssertTrue(true)
                } else {
                    XCTFail()
                }
            } else {
                XCTFail()
            }
            errorThrownExpectation.fulfill()
        }

        wait(for: [errorThrownExpectation], timeout: 1.0)
    }

    /**
     Expect that removing a share under normal circumstances succeeds.
     */
    func testRemoveShare_NormalCircumstances() {
        let fileToRemove = File(name: "My File", hash: nil)
        let contact1 = Contact(identifier: UUID(), displayName: "Contact1",
                               sendAddress: SendAddress(address: "7A5055A5-39A7-4CE4-8061-7C80F918229A",
                                                        keypairName: "my.keypair.name"),
                               receiveAddress: nil,
                               sendList: FileList(hash: nil, files: [fileToRemove]))
        mockStore.contacts = [contact1]
        let model = Model(api: mockAPI,
                          configuration: MockConfiguration(),
                          persistentStore: mockStore,
                          eventCallback: nil)

        let shareRemovedExpectation = expectation(description: "shareRemovedExpectation")

        mockAPI.addResponse = { url in
            Promise(value: AddResponse(name: url.lastPathComponent, hash: UUID().uuidString, size: "12345"))
        }
        mockAPI.publishResponse = { hash, keypair in
            Promise(value: PublishResponse(name: keypair!, value: UUID().uuidString))
        }

        firstly {
            model.unshareFiles([fileToRemove], with: contact1)
        }.then { contact in
            XCTAssertEqual(0, contact.sendList.files.count)
            XCTAssertNotNil(contact.sendList.hash)
            shareRemovedExpectation.fulfill()
        }

        wait(for: [shareRemovedExpectation], timeout: 1.0)
    }

    /**
     Expect that an attempt to remove a shared file with a contact fails if the
     contact does not have a send address set.
     */
    func testRemoveShare_MissingSendAddressKey() {
        let fileToRemove = File(name: "My File", hash: nil)
        let contact1 = Contact(identifier: UUID(), displayName: "Contact1",
                               sendAddress: nil, receiveAddress: nil,
                               sendList: FileList(hash: nil, files: [fileToRemove]))
        mockStore.contacts = [contact1]
        let model = Model(api: mockAPI,
                          configuration: MockConfiguration(),
                          persistentStore: mockStore,
                          eventCallback: nil)

        let errorThrownExpectation = expectation(description: "errorThrownExpectation")

        firstly {
            model.unshareFiles([fileToRemove], with: contact1)
        }.then { contact in
            XCTFail("Should have thrown an error")
        }.catch { error in
            if case HorizonError.fileOperationFailed(let reason) = error {
                if case .sendAddressNotSet = reason {
                    XCTAssertTrue(true)
                } else {
                    XCTFail()
                }
            } else {
                XCTFail()
            }
            errorThrownExpectation.fulfill()
        }

        wait(for: [errorThrownExpectation], timeout: 1.0)
    }

    /**
     Expect that an attempt to remove a shared file fails if the file is
     not in the contacts send list.
     */
    func testRemoveShare_FileNotShared() {
        let fileToRemove = File(name: "My File", hash: "XXX")
        let otherFile = File(name: "My Other File", hash: "XXX")
        let contact1 = Contact(identifier: UUID(), displayName: "Contact1",
                               sendAddress: SendAddress(address: "7A5055A5-39A7-4CE4-8061-7C80F918229A",
                                                        keypairName: "my.keypair.name"),
                               receiveAddress: nil,
                               sendList: FileList(hash: nil, files: [otherFile]))
        mockStore.contacts = [contact1]
        let model = Model(api: mockAPI,
                          configuration: MockConfiguration(),
                          persistentStore: mockStore,
                          eventCallback: nil)

        let errorThrownExpectation = expectation(description: "errorThrownExpectation")

        firstly {
            model.unshareFiles([fileToRemove], with: contact1)
        }.then { contact in
            XCTFail("Should have thrown an error")
        }.catch { error in
            if case HorizonError.fileOperationFailed(let reason) = error {
                if case .fileNotShared = reason {
                    XCTAssertTrue(true)
                } else {
                    XCTFail()
                }
            } else {
                XCTFail()
            }
            errorThrownExpectation.fulfill()
        }

        wait(for: [errorThrownExpectation], timeout: 1.0)
    }


    /**
     Expect that the contact is not updated until the files have been
     unshared (i.e. the new send list been published) in order to avoid
     the UI appearing as though the files are unshared.
     */
    func testRemoveShare_PersistFileListOnlyAfterSuccess() {
        let fileToRemove = File(name: "My File", hash: nil)
        let contact1 = Contact(identifier: UUID(), displayName: "Contact1",
                               sendAddress: SendAddress(address: "7A5055A5-39A7-4CE4-8061-7C80F918229A",
                                                        keypairName: "my.keypair.name"),
                               receiveAddress: nil,
                               sendList: FileList(hash: nil, files: [fileToRemove]))
        mockStore.contacts = [contact1]
        let model = Model(api: mockAPI,
                          configuration: MockConfiguration(),
                          persistentStore: mockStore,
                          eventCallback: nil)

        let errorThrownExpectation = expectation(description: "errorThrownExpectation")

        mockAPI.addResponse = { url in
            return Promise(value: AddResponse(name: url.lastPathComponent, hash: UUID().uuidString, size: "12345"))
        }
        mockAPI.publishResponse = { hash, keypair in
            return Promise(error: NSError() as Error)
        }
        mockStore.createOrUpdateContactHook = { _ in
            XCTFail("Should not have persisted the contact until IPFS publish succeeded")
        }

        firstly {
            model.unshareFiles([fileToRemove], with: contact1)
        }.then { contact in
            XCTFail("Should have thrown an error")
            errorThrownExpectation.fulfill()
        }.catch { _ in
            XCTAssertTrue(true)
            errorThrownExpectation.fulfill()
        }

        wait(for: [errorThrownExpectation], timeout: 1.0)
    }

}

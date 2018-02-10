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

    var testFile: URL {
        return Bundle(for: type(of: self) as AnyClass).url(forResource: "The Byzantine Generals Problem",
                                                           withExtension: "pdf")!
    }

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
        let model = Model(api: mockAPI, persistentStore: mockStore, eventCallback: nil)

        let shareAddedExpectation = expectation(description: "shareAddedExpectation")

        mockAPI.addResponse = { url in
            return AddResponse(name: url.lastPathComponent, hash: UUID().uuidString, size: "12345")
        }
        mockAPI.publishResponse = { hash, keypair in
            PublishResponse(name: keypair!, value: UUID().uuidString)
        }

        firstly {
            model.shareFiles([testFile], with: contact1)
        }.then { contact in
            XCTAssertEqual(1, contact.sendList.files.count)
            XCTAssertEqual("The Byzantine Generals Problem.pdf", contact.sendList.files.first?.name)
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
        let model = Model(api: mockAPI, persistentStore: mockStore, eventCallback: nil)

        let errorThrownExpectation = expectation(description: "errorThrownExpectation")

        firstly {
            model.shareFiles([testFile], with: contact1)
        }.then { contact in
            XCTFail("Should have thrown an error")
        }.catch { error in
            if case HorizonError.shareOperationFailed(let reason) = error {
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
        let model = Model(api: mockAPI, persistentStore: mockStore, eventCallback: nil)

        let errorThrownExpectation = expectation(description: "errorThrownExpectation")

        firstly {
            model.shareFiles([URL(string: "file:///Im/a/teapot.xyz")!], with: contact1)
        }.then { contact in
            XCTFail("Should have thrown an error")
        }.catch { error in
            if case HorizonError.shareOperationFailed(let reason) = error {
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

}

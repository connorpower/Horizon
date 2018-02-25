//
//  ModelTests_Files.swift
//  HorizonCoreTests
//
//  Created by Connor Power on 23.02.18.
//

import XCTest
import IPFSWebService
import PromiseKit
@testable import HorizonCore

class ModelTests_Files: XCTestCase {

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

    func testListFiles() {
        let contact1File1Identifier = UUID().uuidString
        let contact2File1Identifier = UUID().uuidString
        let contact2File2Identifier = UUID().uuidString

        let contact1 = Contact(identifier: UUID(), displayName: "Contact1",
                               sendAddress: nil, receiveAddress: nil,
                               sendList: FileList(hash: nil, files: []),
                               receiveList: FileList(hash: UUID().uuidString, files: [
                                   File(name: "Contact1 File 1", hash: contact1File1Identifier)
                                ]))
        let contact2 = Contact(identifier: UUID(), displayName: "Contact2",
                               sendAddress: nil, receiveAddress: nil,
                               sendList: FileList(hash: nil, files: []),
                               receiveList: FileList(hash: UUID().uuidString, files: [
                                   File(name: "Contact2 File 1", hash: contact2File1Identifier),
                                   File(name: "Contact2 File 2", hash: contact2File2Identifier)
                               ]))
        let contact3 = Contact(identifier: UUID(), displayName: "Contact3",
                               sendAddress: nil, receiveAddress: nil)
        mockStore.contacts = [contact1, contact2, contact3]
        let model = Model(api: mockAPI, configuration: MockConfiguration(), persistentStore: mockStore, eventCallback: nil)

        let files = model.receivedFiles

        XCTAssertEqual(files.count, 3)
        XCTAssertTrue(files.contains(where: { (file, contact) -> Bool in
            return file == File(name: "Contact1 File 1", hash: contact1File1Identifier) && contact == contact1
        }))
        XCTAssertTrue(files.contains(where: { (file, contact) -> Bool in
            return file == File(name: "Contact2 File 1", hash: contact2File1Identifier) && contact == contact2
        }))
        XCTAssertTrue(files.contains(where: { (file, contact) -> Bool in
            return file == File(name: "Contact2 File 2", hash: contact2File2Identifier) && contact == contact2
        }))
    }

    func testFileMatchingHash() {
        let contact1File1Identifier = UUID().uuidString
        let contact2File1Identifier = UUID().uuidString
        let contact2File2Identifier = UUID().uuidString

        let contact1 = Contact(identifier: UUID(), displayName: "Contact1",
                               sendAddress: nil, receiveAddress: nil,
                               sendList: FileList(hash: nil, files: []),
                               receiveList: FileList(hash: UUID().uuidString, files: [
                                   File(name: "Contact1 File 1", hash: contact1File1Identifier)
                                ]))
        let contact2 = Contact(identifier: UUID(), displayName: "Contact2",
                               sendAddress: nil, receiveAddress: nil,
                               sendList: FileList(hash: nil, files: []),
                               receiveList: FileList(hash: UUID().uuidString, files: [
                                   File(name: "Contact2 File 1", hash: contact2File1Identifier),
                                   File(name: "Contact2 File 2", hash: contact2File2Identifier)
                               ]))
        let contact3 = Contact(identifier: UUID(), displayName: "Contact3",
                               sendAddress: nil, receiveAddress: nil)
        mockStore.contacts = [contact1, contact2, contact3]
        let model = Model(api: mockAPI, configuration: MockConfiguration(), persistentStore: mockStore, eventCallback: nil)

        XCTAssertEqual(File(name: "Contact2 File 2", hash: contact2File2Identifier),
                       model.file(matching: contact2File2Identifier))
        XCTAssertNil(model.file(matching: "I do not exist"))
    }

    func testFileMatchingName() {
        let contact1File1Identifier = UUID().uuidString
        let contact2File1Identifier = UUID().uuidString
        let contact2File2Identifier = UUID().uuidString

        let contact1 = Contact(identifier: UUID(), displayName: "Contact1",
                               sendAddress: nil, receiveAddress: nil,
                               sendList: FileList(hash: nil, files: []),
                               receiveList: FileList(hash: UUID().uuidString, files: [
                                File(name: "Contact1 File 1", hash: contact1File1Identifier)
                                ]))
        let contact2 = Contact(identifier: UUID(), displayName: "Contact2",
                               sendAddress: nil, receiveAddress: nil,
                               sendList: FileList(hash: nil, files: []),
                               receiveList: FileList(hash: UUID().uuidString, files: [
                                File(name: "Contact2 File 1", hash: contact2File1Identifier),
                                File(name: "Contact2 File 2", hash: contact2File2Identifier)
                                ]))
        let contact3 = Contact(identifier: UUID(), displayName: "Contact3",
                               sendAddress: nil, receiveAddress: nil)
        mockStore.contacts = [contact1, contact2, contact3]
        let model = Model(api: mockAPI, configuration: MockConfiguration(), persistentStore: mockStore, eventCallback: nil)

        XCTAssertEqual(File(name: "Contact2 File 2", hash: contact2File2Identifier),
                       model.file(named: "Contact2 File 2", sentOrReceivedFrom: contact2))
        XCTAssertNil(model.file(named: "Contact2 File XX", sentOrReceivedFrom: contact2))
    }

    func testDataForFile() {
        let model = Model(api: mockAPI, configuration: MockConfiguration(), persistentStore: mockStore, eventCallback: nil)

        mockAPI.catResponse = { hash in
            return Promise<Data>(value: "XX My Data XX".data(using: .utf8)!)
        }

        let dataReceivedExpectation = expectation(description: "dataReceivedExpectation")

        firstly {
            model.data(for: File(name: "File", hash: UUID().uuidString))
        }.then { data in
            XCTAssertEqual(data, "XX My Data XX".data(using: .utf8)!)
            dataReceivedExpectation.fulfill()
        }.catch { _ in
            XCTFail()
        }

        wait(for: [dataReceivedExpectation], timeout: 1.0)
    }

    func testDataForFile_MissingHash() {
        let model = Model(api: mockAPI, configuration: MockConfiguration(), persistentStore: mockStore, eventCallback: nil)

        let errorThrownExpectation = expectation(description: "errorThrownExpectation")

        firstly {
            model.data(for: File(name: "Contact2 File 1", hash: nil))
        }.then { data in
            XCTFail("Should not have succeeded")
            errorThrownExpectation.fulfill()
        }.catch { error in
            if case HorizonError.fileOperationFailed(let reason) = error {
                if case .fileHashNotSet = reason {
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

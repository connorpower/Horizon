//
//  ContactTests.swift
//  HorizonCoreTests
//
//  Created by Connor Power on 09.02.18.
//  Copyright © 2018 Semantical GmbH & Co. KG. All rights reserved.
//

import XCTest
@testable import HorizonCore

class ContactTests: XCTestCase {
    
    func testBasicProperties() {
        let contact = Contact(identifier: UUID.init(uuidString: "EA76E464-5812-4896-8BF2-EDED3F85A763")!,
                              displayName: "My Display Name",
                              sendAddress: SendAddress(address: "39949FD8-51D6-4B5E-B111-E981CADD2CEE",
                                                       keypairName: "com.horizon.myKeyPairName"),
                              receiveAddress: "13E749A8-B640-4236-8017-542B0FFF5B88")

        XCTAssertEqual(contact.identifier.uuidString, "EA76E464-5812-4896-8BF2-EDED3F85A763")
        XCTAssertEqual(contact.displayName, "My Display Name")
        XCTAssertEqual(contact.sendAddress?.address, "39949FD8-51D6-4B5E-B111-E981CADD2CEE")
        XCTAssertEqual(contact.sendAddress?.keypairName, "com.horizon.myKeyPairName")
        XCTAssertEqual(contact.receiveAddress, "13E749A8-B640-4236-8017-542B0FFF5B88")
    }

    func testMutatingFunctions() {
        let contact = Contact(identifier: UUID.init(uuidString: "EA76E464-5812-4896-8BF2-EDED3F85A763")!,
                              displayName: "My Display Name",
                              sendAddress: SendAddress(address: "39949FD8-51D6-4B5E-B111-E981CADD2CEE",
                                                       keypairName: "com.horizon.myKeyPairName"),
                              receiveAddress: "13E749A8-B640-4236-8017-542B0FFF5B88")

        let newDisplayNameContact = contact.updatingDisplayName("My new display name")
        XCTAssertEqual(newDisplayNameContact.identifier.uuidString, "EA76E464-5812-4896-8BF2-EDED3F85A763")
        XCTAssertEqual(newDisplayNameContact.displayName, "My new display name")
        XCTAssertEqual(newDisplayNameContact.sendAddress?.address, "39949FD8-51D6-4B5E-B111-E981CADD2CEE")
        XCTAssertEqual(newDisplayNameContact.sendAddress?.keypairName, "com.horizon.myKeyPairName")
        XCTAssertEqual(newDisplayNameContact.receiveAddress, "13E749A8-B640-4236-8017-542B0FFF5B88")

        let newSendAddress = SendAddress(address: "78F66FA7-DC5B-49FD-ADA4-EA34A8CA82EF",
                                         keypairName: "My new keypair name")
        let newSendAddressContact = contact.updatingSendAddress(newSendAddress)
        XCTAssertEqual(newSendAddressContact.identifier.uuidString, "EA76E464-5812-4896-8BF2-EDED3F85A763")
        XCTAssertEqual(newSendAddressContact.displayName, "My Display Name")
        XCTAssertEqual(newSendAddressContact.sendAddress?.address, "78F66FA7-DC5B-49FD-ADA4-EA34A8CA82EF")
        XCTAssertEqual(newSendAddressContact.sendAddress?.keypairName, "My new keypair name")
        XCTAssertEqual(newSendAddressContact.receiveAddress, "13E749A8-B640-4236-8017-542B0FFF5B88")

        let newReceiveAddressContact = contact.updatingReceiveAddress("FFD2447C-6F88-44BB-B433-360E96D490BE")
        XCTAssertEqual(newReceiveAddressContact.identifier.uuidString, "EA76E464-5812-4896-8BF2-EDED3F85A763")
        XCTAssertEqual(newReceiveAddressContact.displayName, "My Display Name")
        XCTAssertEqual(newReceiveAddressContact.sendAddress?.address, "39949FD8-51D6-4B5E-B111-E981CADD2CEE")
        XCTAssertEqual(newReceiveAddressContact.sendAddress?.keypairName, "com.horizon.myKeyPairName")
        XCTAssertEqual(newReceiveAddressContact.receiveAddress, "FFD2447C-6F88-44BB-B433-360E96D490BE")

        let nilSendAddressContact = contact.updatingSendAddress(nil)
        XCTAssertEqual(nilSendAddressContact.identifier.uuidString, "EA76E464-5812-4896-8BF2-EDED3F85A763")
        XCTAssertEqual(nilSendAddressContact.displayName, "My Display Name")
        XCTAssertNil(nilSendAddressContact.sendAddress?.address)
        XCTAssertNil(nilSendAddressContact.sendAddress?.keypairName)
        XCTAssertEqual(nilSendAddressContact.receiveAddress, "13E749A8-B640-4236-8017-542B0FFF5B88")

        let nilReceiveAddressContact = contact.updatingReceiveAddress(nil)
        XCTAssertEqual(nilReceiveAddressContact.identifier.uuidString, "EA76E464-5812-4896-8BF2-EDED3F85A763")
        XCTAssertEqual(nilReceiveAddressContact.displayName, "My Display Name")
        XCTAssertEqual(nilReceiveAddressContact.sendAddress?.address, "39949FD8-51D6-4B5E-B111-E981CADD2CEE")
        XCTAssertEqual(nilReceiveAddressContact.sendAddress?.keypairName, "com.horizon.myKeyPairName")
        XCTAssertNil(nilReceiveAddressContact.receiveAddress)
    }

    func testEquality0() {
        let contact1 = Contact(identifier: UUID(uuidString: "14D15E2B-8B5C-4404-96C6-67245A011903")!,
                               displayName: "My Display Name", sendAddress: nil, receiveAddress: nil)
        let contact2 = Contact(identifier: UUID.init(uuidString: "14D15E2B-8B5C-4404-96C6-67245A011903")!,
                               displayName: "My Display Name", sendAddress: nil, receiveAddress: nil)

        XCTAssertTrue(contact1 == contact2)
    }

    func testEquality1() {
        let contact1 = Contact(identifier: UUID(uuidString: "14D15E2B-8B5C-4404-96C6-67245A011903")!,
                               displayName: "My Display Name",
                               sendAddress: SendAddress(address: "AAA", keypairName: "KeyPairName"),
                               receiveAddress: "AAA")
        let contact2 = Contact(identifier: UUID.init(uuidString: "14D15E2B-8B5C-4404-96C6-67245A011903")!,
                               displayName: "My Display Name",
                               sendAddress: SendAddress(address: "AAA", keypairName: "KeyPairName"),
                               receiveAddress: "AAA")

        XCTAssertTrue(contact1 == contact2)
    }

    func testEquality2() {
        let contact1 = Contact(identifier: UUID(uuidString: "14D15E2B-8B5C-4404-96C6-67245A011903")!,
                               displayName: "My Display Name",
                               sendAddress: SendAddress(address: "AAA", keypairName: "KeyPairName"),
                               receiveAddress: "AAA")
        let contact2 = Contact(identifier: UUID(uuidString: "14D15E2B-8B5C-4404-96C6-67245A011903")!,
                               displayName: "My Other Name",
                               sendAddress: SendAddress(address: "AAA", keypairName: "KeyPairName"),
                               receiveAddress: "AAA")

        XCTAssertTrue(contact1 != contact2)
    }

    func testEquality3() {
        let contact1 = Contact(identifier: UUID(uuidString: "14D15E2B-8B5C-4404-96C6-67245A011903")!,
                               displayName: "My Display Name",
                               sendAddress: SendAddress(address: "AAA", keypairName: "KeyPairName"),
                               receiveAddress: "AAA")
        let contact2 = Contact(identifier: UUID(uuidString: "14D15E2B-8B5C-4404-96C6-67245A011903")!,
                               displayName: "My Display Name",
                               sendAddress: SendAddress(address: "XXXXXXXXXXXXXXXXX", keypairName: "KeyPairName"),
                               receiveAddress: "AAA")

        XCTAssertTrue(contact1 != contact2)
    }

    func testEquality4() {
        let contact1 = Contact(identifier: UUID(uuidString: "14D15E2B-8B5C-4404-96C6-67245A011903")!,
                               displayName: "My Display Name",
                               sendAddress: SendAddress(address: "AAA", keypairName: "KeyPairName"),
                               receiveAddress: "AAA")
        let contact2 = Contact(identifier: UUID(uuidString: "14D15E2B-8B5C-4404-96C6-67245A011903")!,
                               displayName: "My Display Name",
                               sendAddress: SendAddress(address: "AAA", keypairName: "MY OTHER KEY PAIR NAME"),
                               receiveAddress: "AAA")

        XCTAssertTrue(contact1 != contact2)
    }

    func testEquality5() {
        let contact1 = Contact(identifier: UUID(uuidString: "14D15E2B-8B5C-4404-96C6-67245A011903")!,
                               displayName: "My Display Name",
                               sendAddress: SendAddress(address: "AAA", keypairName: "KeyPairName"),
                               receiveAddress: "AAA")
        let contact2 = Contact(identifier: UUID(uuidString: "14D15E2B-8B5C-4404-96C6-67245A011903")!,
                               displayName: "My Display Name",
                               sendAddress: nil,
                               receiveAddress: "AAA")

        XCTAssertTrue(contact1 != contact2)
    }

    func testEquality6() {
        let contact1 = Contact(identifier: UUID(uuidString: "14D15E2B-8B5C-4404-96C6-67245A011903")!,
                               displayName: "My Display Name",
                               sendAddress: SendAddress(address: "AAA", keypairName: "KeyPairName"),
                               receiveAddress: "AAA")
        let contact2 = Contact(identifier: UUID(uuidString: "14D15E2B-8B5C-4404-96C6-67245A011903")!,
                               displayName: "My Display Name",
                               sendAddress: SendAddress(address: "AAA", keypairName: "KeyPairName"),
                               receiveAddress: "XXXXXXXXXXXXXXXXX")

        XCTAssertTrue(contact1 != contact2)
    }

    func testEquality7() {
        let contact1 = Contact(identifier: UUID(uuidString: "14D15E2B-8B5C-4404-96C6-67245A011903")!,
                               displayName: "My Display Name",
                               sendAddress: SendAddress(address: "AAA", keypairName: "KeyPairName"),
                               receiveAddress: "AAA")
        let contact2 = Contact(identifier: UUID(uuidString: "14D15E2B-8B5C-4404-96C6-67245A011903")!,
                               displayName: "My Display Name",
                               sendAddress: SendAddress(address: "AAA", keypairName: "KeyPairName"),
                               receiveAddress: nil)

        XCTAssertTrue(contact1 != contact2)
    }

}

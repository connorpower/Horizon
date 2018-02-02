//
//  FileTests.swift
//  HorizonCoreTests
//
//  Created by Connor Power on 05.01.18.
//  Copyright © 2018 Semantical GmbH & Co. KG. All rights reserved.
//

import XCTest
@testable import HorizonCore

class FileTests: XCTestCase {

    func testEquality1() {
        let file1 = File(name: "My File", hash: nil)
        let file2 = File(name: "My File", hash: nil)

        XCTAssertTrue(file1 == file2)
    }

    func testEquality2() {
        let file1 = File(name: "My File", hash: nil)
        let file2 = File(name: "My Other File", hash: nil)

        XCTAssertTrue(file1 != file2)
    }

    func testEquality3() {
        let file1 = File(name: "My File", hash: "14D15E2B-8B5C-4404-96C6-67245A011903")
        let file2 = File(name: "My Other File", hash: "14D15E2B-8B5C-4404-96C6-67245A011903")

        XCTAssertTrue(file1 != file2)
    }

    func testEquality4() {
        let file1 = File(name: "My File", hash: "14D15E2B-8B5C-4404-96C6-67245A011903")
        let file2 = File(name: "My File", hash: "8C6692AA-DFF0-4CA4-84FD-8EFCF1D2FEBD")

        XCTAssertTrue(file1 != file2)
    }

}

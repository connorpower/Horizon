//
//  FileListTests.swift
//  HorizonCoreTests
//
//  Created by Connor Power on 05.01.18.
//  Copyright © 2018 Semantical GmbH & Co. KG. All rights reserved.
//

import XCTest
@testable import HorizonCore

class FileListTests: XCTestCase {

    func test() {
        let file1 = File(name: "My File", hash: "00DBF8D3-6E3F-4C33-A104-DBB8D4B8766B")
        let file2 = File(name: "My Other File", hash: "14D15E2B-8B5C-4404-96C6-67245A011903")

        let fileList = FileList(hash: "10EFAA6B-2943-4DAD-BB19-FD89A6732C8E", files: [file1, file2])

        XCTAssertEqual(fileList.hash, "10EFAA6B-2943-4DAD-BB19-FD89A6732C8E")
        XCTAssertTrue(fileList.files.contains(file1))
        XCTAssertTrue(fileList.files.contains(file2))
        XCTAssertEqual(2, fileList.files.count)
    }

}

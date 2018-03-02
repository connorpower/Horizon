//
//  FileList.swift
//  HorizonCore
//
//  Created by Connor Power on 12.01.18.
//  Copyright © 2018 Connor Power. All rights reserved.
//

import Foundation

/**
 A simple serializable type representing a list of files, either
 shared or received.
 */
public struct FileList: Codable {

    // MARK: - Properties

    /**
     Each file list is itself stored in IPFS as a file. `hash`
     points to the list itself. If the file list has not yet
     been published to IPFS, then this constant will be nil.
     */
    public let hash: String?

    /**
     The list of shared files.
     */
    public let files: [File]

    // MARK: - Initializer

    public init(hash: String?, files: [File]) {
        self.hash = hash
        self.files = files
    }

    // MARK: - Functions

    public func updatingHash(_ newHash: String) -> FileList {
        return FileList(hash: newHash, files: files)
    }

}

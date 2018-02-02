//
//  FileList.swift
//  HorizonCore
//
//  Created by Connor Power on 12.01.18.
//  Copyright © 2018 Semantical GmbH & Co. KG. All rights reserved.
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

}

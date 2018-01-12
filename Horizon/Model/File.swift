//
//  File.swift
//  Horizon
//
//  Created by Jürgen on 02.11.17.
//  Copyright © 2017 Semantical GmbH & Co. KG. All rights reserved.
//

import Foundation

/**
 A simple representation of an IPFS file. Directories/trees
 are not yet supported.
 */
struct File: Codable {

    /**
     The name of the file itself as recorded in IPFS.
     */
    let name: String

    /**
     The IPFS hash of the file.
     */
    let hash: String?

}

extension File: Equatable {
    public static func == (lhs: File, rhs: File) -> Bool {
        return lhs.name == rhs.name && lhs.hash == rhs.hash
    }
}

extension File: Hashable {
    var hashValue: Int {
        return name.hashValue ^ (hash ?? "").hashValue &* 16777619
    }
}

//
//  File.swift
//  HorizonCore
//
//  Created by Jürgen on 02.11.17.
//  Copyright © 2017 Semantical GmbH & Co. KG. All rights reserved.
//

import Foundation

/**
 A simple representation of an IPFS file. Directories/trees
 are not yet supported.
 */
public struct File: Codable {

    /**
     The name of the file itself as recorded in IPFS.
     */
    public let name: String

    /**
     The IPFS hash of the file.
     */
    public let hash: String?

}

extension File: Equatable {
    public static func == (lhs: File, rhs: File) -> Bool {
        return lhs.name == rhs.name && lhs.hash == rhs.hash
    }
}

extension File: Hashable {
    public var hashValue: Int {
        return name.hashValue ^ (hash ?? "").hashValue &* 16777619
    }
}

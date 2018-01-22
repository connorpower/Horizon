//
// RemoveKeyResponse.swift
//
// Generated by swagger-codegen
// https://github.com/swagger-api/swagger-codegen
//

import Foundation



open class RemoveKeyResponse: Codable {

    /** A list of keypairs. */
    public var keys: [Key]


    
    public init(keys: [Key]) {
        self.keys = keys
    }
    

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {

        var container = encoder.container(keyedBy: String.self)

        try container.encode(keys, forKey: "Keys")
    }

    // Decodable protocol methods

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: String.self)

        keys = try container.decode([Key].self, forKey: "Keys")
    }
}


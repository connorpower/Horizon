//
//  DataModel.swift
//  Horizon
//
//  Created by Jürgen on 02.11.17.
//  Copyright © 2017 Semantical GmbH & Co. KG. All rights reserved.
//

import Foundation

struct DataModel {
    var contacts: [Contact] = []

    init() {
        contacts = [
            Contact(name: "Connor", senderId: "", receiverId: ""),
            Contact(name: "Steffen", senderId: "", receiverId: ""),
        ]
    }
    
    func files(for contact: Contact) -> [File] {
        if contact.name == "Connor" {
            return [File(name: "1"), File(name: "2"), File(name: "3")]
        }
        else {
            return [File(name: "a"), File(name: "b"), File(name: "c")]
        }
    }
    
    func add(fileURLs: [NSURL], to contact: Contact) {
        print("\(fileURLs) --> \(contact.name)")
    }
}

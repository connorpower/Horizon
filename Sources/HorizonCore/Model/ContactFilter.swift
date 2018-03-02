//
//  ContactFilter.swift
//  HorizonCore
//
//  Created by Connor Power on 16.02.18.
//  Copyright © 2018 Connor Power. All rights reserved.
//

import Foundation

/**
 A simple enum type which allows filtering or restricting
 a command to either a particular contact, or to all contacts.

 Provides better readability for various model APIs.
 */
public enum ContactFilter {
    case allContacts
    case specificContact(String)

    /**
     Initializer. Takes an optional string, which if nil returns
     `ContactFilter.allContacts` otherwise `ContactFilter.specificContact`
     */
    public init(optionalContact: String? = nil) {
        if let contact = optionalContact {
            self = .specificContact(contact)
        } else {
            self = .allContacts
        }
    }

}

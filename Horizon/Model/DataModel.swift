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
        ]
    }
}

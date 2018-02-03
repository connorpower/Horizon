//
//  PeersHandler.swift
//  horizon-cli
//
//  Created by Connor Power on 22.01.18.
//  Copyright © 2018 Semantical GmbH & Co. KG. All rights reserved.
//

import Foundation
import HorizonCore

/**
 A handler for all peer commands. Currently these are:

     $ horizon-cli peers list
     $ horizon-cli peers add {peer-name}
     $ horizon-cli peers remove {peer-name}
     $ horizon-cli peers edit {peer-name}

 */
struct PeersHandler: Handler {

    // MARK: - Constants

    private let commands = [
        Command(name: "list", expectedNumArgs: 0, help: """
            horizon-cli peers list
              Lists all peers which have been added to Horizon.
              This command takes no arguments.
            """),
        Command(name: "add", expectedNumArgs: 1, help: """
            horizon-cli peers add {name}
              Adds a new peer to Horizon and generates an IPNS key which will
              be used for sharing files with the peer. The new peer's shared file
              list can be added after the fact using `ipfs peer edit {name}`.

              name: A short name for the peer.
            """)
    ]

    // MARK: - Properties

    private let model: Model

    private let arguments: [String]

    private let completionHandler: () -> Never
    private let errorHandler: () -> Never

    // MARK: - Handler Protocol

    init(model: Model, arguments: [String], completion: @escaping () -> Never, error: @escaping () -> Never) {
        self.model = model
        self.arguments = arguments
        self.completionHandler = completion
        self.errorHandler = error
    }

    func run() {
        guard !arguments.isEmpty else {
            printHelp()
            errorHandler()
        }

        guard let command = commands.filter({$0.name == arguments.first}).first else {
            printHelp()
            errorHandler()
        }

        if command.expectedNumArgs != arguments.count - 1 {
            print(command.help)
            errorHandler()
        }

        switch command.name {
        case "add":
            if let name = arguments.dropFirst().first {
                addPeer(name: name)
            } else {
                print(command.help)
                errorHandler()
            }
        default:
            print(command.help)
            errorHandler()
        }
    }

    // MARK: - Private Functions

    private func printHelp() {
        print("No matched commands. Print help...")
    }

    private func addPeer(name: String) {
        model.addContact(name: name) { contact, error in
            if contact != nil {
                self.completionHandler()
            } else if let error = error {
                if case HorizonError.addContactFailed(let reason) = error {
                    if case .contactAlreadyExists = reason {
                        print("Contact already exists.")
                        self.errorHandler()
                    }
                }

                print("Failed to add peer. Is IPFS running?")
                self.errorHandler()
            }
        }
    }

}

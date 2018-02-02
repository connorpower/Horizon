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
            completionHandler()
        }

        guard let command = commands.filter({$0.name == arguments.first}).first else {
            printHelp()
            return
        }

        if command.expectedNumArgs != arguments.count - 1 {
            print(command.help)
            return
        }

        switch command.name {
        case "add":
            addPeer(arguments: Array(arguments.dropFirst()))
            break
        default:
            print(command.help)
            return
        }
    }

    // MARK: - Private Functions

    private func printHelp() {
        print("No matched commands. Print help...")
    }

    private func addPeer(arguments: [String]) {
        guard let name = arguments.first else {
            return
        }

        let keypairName = "com.semantical.horizon-cli.peer.\(name)"

        model.listKeys(completion: { (keys) in
            guard let keys = keys else {
                print("Failed to list current keypairs.\nIs IPFS running?")
                self.errorHandler()
            }

            guard !keys.contains(keypairName) else {
                print("Peer already exists.")
                self.errorHandler()
            }

            self.model.generateKey(name: keypairName) { (result: (keypairName: String, hash: String)?) in
                if let result = result {
                    let contact = Contact(identifier: UUID(), displayName: name,
                                          sendListKey: result.keypairName, receiveListHash: nil)

                    self.model.addContact(contact: contact)
                    self.completionHandler()
                } else {
                    print("Failed to generate keypair \(keypairName).\nIs IPFS running?")
                    self.errorHandler()
                }
            }
        })
    }

}

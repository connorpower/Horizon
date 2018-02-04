//
//  ContactsHandler.swift
//  horizon-cli
//
//  Created by Connor Power on 22.01.18.
//  Copyright © 2018 Semantical GmbH & Co. KG. All rights reserved.
//

import Foundation
import HorizonCore

struct ContactsHandler: Handler {

    // MARK: - Constants

    let help = """
    USAGE
      horizon-cli contacts - Create and manage Horizon contacts

    SYNOPSIS
      horizon-cli contacts

    DESCRIPTION

      'horizon-cli contacts add' adds a new contact for usage with Horizon.
      An address for the send channel will be immediately created. This address
      consists of an IPNS hash and can be shared with the contact to allow
      them to receive files from you.
      The contact should run the same procedure on their side and provide you
      with the address of their shared list.
      This becomes the receive-address which you can set manually later using
      'horizon-cli contacts set-receive-addr <name> <receive-address>'

        > horizon-cli contacts add mmusterman
        > horizon-cli contacts set-rcv-addr mmusterman QmSomeHash

      'horizon-cli contacts ls' lists the available contacts.

        > horizon-cli contacts ls
        joe
        mmusterman

      'horizon-cli contacts info <name>' prints a given contact to the screen,
      showing the current values for the send address and receive address.

        > horizon-cli contacts info mmusterman
        Display name:     mmusterman
        Send address:     QmSomeHash
        Receive address:  QmSomeHash
        IPFS keypair:     com-semantical.horizon-cli.mmusterman

      'horizon-cli contacts rm <name>' removes a given contact from Horizon.
      All files shared with the contact until this point remain available to
      the contact.

        > horizon-cli contacts rm mmusterman

      'horizon-cli contacts rename <name> <newName>' renames a given contact
      but otherwise keeps all information and addresses the same.

        > horizon-cli contacts rename mmusterman max

      'horizon-cli contacts set-rcv-addr <name> <receive-hash>' sets the
      receive address for a given contact. The contact should provide you
      with this address – the result of them adding you as a contact to
      their horizon instance.

        > horizon-cli contacts set-rcv-addr mmusterman QmSomeHash

      SUBCOMMANDS
        horizon-cli contacts add <name>                    - Create a new contact
        horizon-cli contacts ls                            - List all contacts
        horizon-cli contacts info <name>                   - Prints contact and associated details
        horizon-cli contacts rm <name>                     - Removes contact
        horizon-cli contacts rename <name> <newName>       - Renames contact
        horizon-cli contacts set-rcv-addr <name> <hash>    - Sets the receive address for a contact

        Use 'horizon-cli contacts <subcmd> --help' for more information about each command.

    """

    private let commands = [
        Command(name: "ls", expectedNumArgs: 0, help: """
            horizon-cli contacts ls
              Lists all contacts which have been added to Horizon.
              This command takes no arguments.
            """),
        Command(name: "add", expectedNumArgs: 1, help: """
            horizon-cli contacts add <name>
              Adds a new peer to Horizon and generates an IPNS key which will
              be used for sharing files with the peer.

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
        guard !arguments.isEmpty, let command = commands.filter({$0.name == arguments.first}).first else {
            print(help)
            errorHandler()
        }

        let commandArguments = arguments.dropFirst()
        if command.expectedNumArgs != commandArguments.count {
            print(command.help)
            errorHandler()
        }

        switch command.name {
        case "add":
            if let name = commandArguments.first {
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

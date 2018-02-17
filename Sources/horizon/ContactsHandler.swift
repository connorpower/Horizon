//
//  ContactsHandler.swift
//  horizon
//
//  Created by Connor Power on 22.01.18.
//  Copyright © 2018 Semantical GmbH & Co. KG. All rights reserved.
//

import Foundation
import HorizonCore
import PromiseKit

struct ContactsHandler: Handler {

    // MARK: - Constants

    let longHelp = """
    USAGE
      horizon contacts - Create and manage Horizon contacts

    SYNOPSIS
      horizon contacts

    DESCRIPTION

      'horizon contacts add' adds a new contact for usage with Horizon.
      An address for the send channel will be immediately created. This address
      consists of an IPNS hash and can be shared with the contact to allow
      them to receive files from you.
      The contact should run the same procedure on their side and provide you
      with the address of their shared list.
      This becomes the receive-address which you can set manually later using
      'horizon contacts set-receive-addr <name> <receive-address>'

        > horizon contacts add mmusterman
        > horizon contacts set-rcv-addr mmusterman QmSomeHash

      'horizon contacts ls' lists the available contacts.

        > horizon contacts ls
        joe
        mmusterman

      'horizon contacts info <name>' prints a given contact to the screen,
      showing the current values for the send address and receive address.

        > horizon contacts info mmusterman
        mmusterman
        Send address:     QmSomeHash
        Receive address:  QmSomeHash
        IPFS keypair:     com-semantical.horizon.mmusterman

        joe
        Send address:     QmSomeHash
        Receive address:  QmSomeHash
        IPFS keypair:     com-semantical.horizon.joe

      'horizon contacts rm <name>' removes a given contact from Horizon.
      All files shared with the contact until this point remain available to
      the contact.

        > horizon contacts rm mmusterman

      'horizon contacts rename <name> <new-name>' renames a given contact
      but otherwise keeps all information and addresses the same.

        > horizon contacts rename mmusterman max

      'horizon contacts set-rcv-addr <name> <hash>' sets the receive address
      for a given contact. The contact should provide you with this address –
      the result of them adding you as a contact to their horizon instance.

        > horizon contacts set-rcv-addr mmusterman QmSomeHash

      SUBCOMMANDS
        horizon contacts help                          - Displays detailed help information
        horizon contacts add <name>                    - Create a new contact
        horizon contacts ls                            - List all contacts
        horizon contacts info <name>                   - Prints contact and associated details
        horizon contacts rm <name>                     - Removes contact
        horizon contacts rename <name> <new-name>      - Renames contact
        horizon contacts set-rcv-addr <name> <hash>    - Sets the receive address for a contact

        Use 'horizon contacts <subcmd> --help' for more information about each command.

    """

    private let shortHelp = """
    USAGE
      horizon contacts - Create and manage Horizon contacts

    SYNOPSIS
      horizon contacts

    SUBCOMMANDS
        horizon contacts help                          - Displays detailed help information
        horizon contacts add <name>                    - Create a new contact
        horizon contacts ls                            - List all contacts
        horizon contacts info [<name>]                 - Prints contact and associated details
        horizon contacts rm <name>                     - Removes contact
        horizon contacts rename <name> <new-name>      - Renames contact
        horizon contacts set-rcv-addr <name> <hash>    - Sets the receive address for a contact

        Use 'horizon contacts <subcmd> --help' for more information about each command.

    """

    private let commands = [
        Command(name: "add", allowableNumberOfArguments: [1], help: """
            horizon contacts add <name>
              'horizon contacts add' adds a new contact for usage with Horizon.
              An address for the send channel will be immediately created. This address
              consists of an IPNS hash and can be shared with the contact to allow
              them to receive files from you.
              The contact should run the same procedure on their side and provide you
              with the address of their shared list.
              This becomes the receive-address which you can set manually later using
              'horizon contacts set-receive-addr <name> <receive-address>'

                > horizon contacts add mmusterman
                > horizon contacts set-rcv-addr mmusterman QmSomeHash

            """),
        Command(name: "ls", allowableNumberOfArguments: [0], help: """
            horizon contacts ls
              'horizon contacts ls' lists the available contacts by their short
              display names.

                > horizon contacts ls
                joe
                mmusterman

            """),
        Command(name: "info", allowableNumberOfArguments: [0, 1], help: """
            horizon contacts info [<name>]
              'horizon contacts info <name>' prints a given contact to the screen,
              showing the current values for the send address and receive address.

                > horizon contacts info mmusterman
                mmusterman
                Send address:     QmSomeHash
                Receive address:  QmSomeHash
                IPFS keypair:     com-semantical.horizon.mmusterman

            """),
        Command(name: "rm", allowableNumberOfArguments: [1], help: """
            horizon contacts rm <name>
              'horizon contacts rm <name>' removes a given contact from Horizon.
              All files shared with the contact until this point remain available to
              the contact.

                > horizon contacts rm mmusterman

            """),
        Command(name: "rename", allowableNumberOfArguments: [2], help: """
            horizon contacts rename <name> <new-name>
              'horizon contacts rename <name> <new-name>' renames a given contact
              but otherwise keeps all information and addresses the same.

                > horizon contacts rename mmusterman max

            """),
        Command(name: "set-rcv-addr", allowableNumberOfArguments: [2], help: """
            horizon contacts set-rcv-addr <name> <hash>
              'horizon contacts set-rcv-addr <name> <hash>' sets the
              receive address for a given contact. The contact should provide you
              with this address – the result of them adding you as a contact to
              their horizon instance.

                > horizon contacts set-rcv-addr mmusterman QmSomeHash

            """),
    ]

    // MARK: - Properties

    private let model: Model
    private let config: ConfigurationProvider

    private let arguments: [String]

    private let completionHandler: () -> Never
    private let errorHandler: () -> Never

    // MARK: - Handler Protocol

    init(model: Model, config: ConfigurationProvider, arguments: [String],
         completion: @escaping () -> Never, error: @escaping () -> Never) {
        self.model = model
        self.config = config
        self.arguments = arguments
        self.completionHandler = completion
        self.errorHandler = error
    }

    func run() {
        if !arguments.isEmpty, ["help", "-h", "--help"].contains(arguments[0]) {
            print(longHelp)
            completionHandler()
        }

        guard !arguments.isEmpty, let command = commands.filter({$0.name == arguments[0]}).first else {
            print(shortHelp)
            errorHandler()
        }

        let commandArguments = Array(arguments.dropFirst())
        if !command.allowableNumberOfArguments.contains(commandArguments.count) {
            print(command.help)
            errorHandler()
        }

        switch command.name {
        case "add":
            addContact(name: commandArguments[0])
        case "ls":
            listContacts()
        case "info":
            let contactFilter = ContactFilter(optionalContact: commandArguments.first)

            listContactInfo(for: contactFilter)
        case "rm":
            removeContact(name: commandArguments[0])
        case "rename":
            let name = commandArguments[0]
            let newName = commandArguments[1]
            renameContact(name, to: newName)
        case "set-rcv-addr":
            let name = commandArguments[0]
            let recieveAddress = commandArguments[1]
            setReceiveAddress(of: name, to: recieveAddress)
        default:
            print(command.help)
            errorHandler()
        }
    }

    // MARK: - Private Functions

    private func addContact(name: String) {
        firstly {
            return model.addContact(name: name)
        }.then { contact in
            self.completionHandler()
        }.catch { error in
            if case HorizonError.contactOperationFailed(let reason) = error {
                if case .contactAlreadyExists = reason {
                    print("Contact already exists.")
                    self.errorHandler()
                }
            }

            print("Failed to add contact. Have you started the horizon daemon?")
            self.errorHandler()
        }
    }

    private func listContactInfo(for contactFilter: ContactFilter) {
        let contacts:[Contact]

        switch contactFilter {
        case .specificContact(let name):
            guard let specificContact = model.contact(named: name) else {
                print("Contact does not exist.")
                errorHandler()
            }
            contacts = [specificContact]
        case .allContacts:
            contacts = model.contacts
        }

        for contact in contacts {
            print("""
                \(contact.displayName)
                Send address:    \(contact.sendAddress?.address ?? "nil")
                Receive address: \(contact.receiveAddress ?? "nil")
                IPFS keypair:    \(contact.sendAddress?.keypairName ?? "nil")

                """)
        }
        completionHandler()
    }

    private func listContacts() {
        for contact in model.contacts {
            print(contact.displayName)
        }

        completionHandler()
    }

    private func removeContact(name: String) {
        firstly {
            model.removeContact(name: name)
        }.then {
            self.completionHandler()
        }.catch { error in
            if case HorizonError.contactOperationFailed(let reason) = error {
                if case .contactDoesNotExist = reason {
                    print("Contact does not exist.")
                    self.errorHandler()
                }
            }

            print("Failed to remove contact. Have you started the horizon daemon?")
            self.errorHandler()
        }
    }

    private func renameContact(_ name: String, to newName: String) {
        firstly {
            model.renameContact(name, to: newName)
        }.then { _ in
            self.completionHandler()
        }.catch { error in
            if case HorizonError.contactOperationFailed(let reason) = error {
                if case .contactDoesNotExist = reason {
                    print("Contact does not exist.")
                    self.errorHandler()
                } else if case .contactAlreadyExists = reason {
                    print("Another contact already exists with the name \(newName).")
                    self.errorHandler()
                }
            }

           print("Failed to rename contact. Have you started the horizon daemon?")
           self.errorHandler()
        }
    }

    private func setReceiveAddress(of name: String, to recieveAddress: String) {
        guard let contact = model.contact(named: name) else {
            print("Contact does not exist.")
            self.errorHandler()
        }

        model.updateReceiveAddress(for: contact, to: recieveAddress)
        self.completionHandler()
    }

}

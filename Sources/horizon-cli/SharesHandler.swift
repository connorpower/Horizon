//
//  SharesHandler.swift
//  horizon-cli
//
//  Created by Connor Power on 09.02.18.
//

import Foundation
import HorizonCore
import PromiseKit

struct SharesHandler: Handler {

    // MARK: - Constants

    let longHelp = """
    USAGE
      horizon-cli shares - Share files with Horizon contacts

    SYNOPSIS
      horizon-cli shares

    DESCRIPTION

      'horizon-cli shares add' adds a new file to be shared with a contact.
      The file will be added to IPFS. The list of files shared with the
      contacted will be updated and in turn also re-published to IPFS.

        > horizon-cli shares add mmusterman "./The Byzantine Generals Problem.pdf"

      'horizon-cli shares ls [<contact-name>]' lists all files you are sharing
      with other contacts.

        > horizon-cli shares ls
        mmusterman
        QmSomeHash: "The Byzantine Generals Problem.pdf"
        QmSomeHash: "This is Water, David Foster Wallace.pdf"

        jbloggs
        QmSomeHash: "IPFS - Content Addressed, Versioned, P2P File System (DRAFT 3).pdf"

      You may optionally filter by only a given contact.

        > horizon-cli shares ls jbloggs
        QmSomeHash: "IPFS - Content Addressed, Versioned, P2P File System (DRAFT 3).pdf"

      'horizon-cli shares rm <contact-name> <file>' unshares a file with
      the given contact, and if the file is shared with no other contacts
      - removes the file from IPFS.

      Note that unsharing a file is not a security mechanism. There is no
      guarantee that your contact will receive the updated file list sans
      the removed file, or that the contact could not simply access the file
      via its direct IPFS hash.

        > horizon-cli shares rm "./La cryptographie militaire, Auguste Kerckhoffs.txt"

      SUBCOMMANDS
        horizon-cli shares help                          - Displays detailed help information
        horizon-cli shares add <contact-name> <file>     - Adds a new file to be shared with a contact
        horizon-cli shares ls [<contact-name>]           - Lists all shared files (optionally for a given contact)
        horizon-cli shares rm <contact-name> <file>      - Removes a file which was shared with a contact

        Use 'horizon-cli shares <subcmd> --help' for more information about each command.

    """

    private let shortHelp = """
    USAGE
      horizon-cli shares - Share files with Horizon contacts

    SYNOPSIS
      horizon-cli shares

      SUBCOMMANDS
        horizon-cli shares help                          - Displays detailed help information
        horizon-cli shares add <contact-name> <file>     - Adds a new file to be shared with a contact
        horizon-cli shares ls [<contact-name>]           - Lists all shared files (optionally for a given contact)
        horizon-cli shares rm <contact-name> <file>      - Removes a file which was shared with a contact

        Use 'horizon-cli shares <subcmd> --help' for more information about each command.

    """

    private let commands = [
        Command(name: "add", allowableNumberOfArguments: [2], help: """
            horizon-cli shares add <contact-name> <file>
              'horizon-cli shares add' adds a new file to be shared with a contact.
              The file will be added to IPFS. The list of files shared with the
              contacted will be updated and in turn also re-published to IPFS.

                > horizon-cli shares add mmusterman "./The Byzantine Generals Problem.pdf"

            """),
        Command(name: "ls", allowableNumberOfArguments: [0], help: """
            horizon-cli shares ls [<contact-name>]
              'horizon-cli shares ls [<contact-name>]' lists all files you are sharing
              with other contacts.

                > horizon-cli shares ls
                mmusterman
                QmSomeHash: "The Byzantine Generals Problem.pdf"
                QmSomeHash: "This is Water, David Foster Wallace.pdf"

                jbloggs
                QmSomeHash: "IPFS - Content Addressed, Versioned, P2P File System (DRAFT 3).pdf"

              You may optionally filter by only a given contact.

                > horizon-cli shares ls jbloggs
                QmSomeHash: "IPFS - Content Addressed, Versioned, P2P File System (DRAFT 3).pdf"

            """),
        Command(name: "rm", allowableNumberOfArguments: [2], help: """
            horizon-cli shares rm <contact-name> <file>
              'horizon-cli shares rm <contact-name> <file>' unshares a file with
              the given contact, and if the file is shared with no other contacts
              - removes the file from IPFS.

              Note that unsharing a file is not a security mechanism. There is no
              guarantee that your contact will receive the updated file list sans
              the removed file, or that the contact could not simply access the file
              via its direct IPFS hash.

                > horizon-cli shares rm "./La cryptographie militaire, Auguste Kerckhoffs.txt"

            """),
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
        if !arguments.isEmpty, ["help", "-h", "--help"].contains(arguments[0]) {
            print(longHelp)
            completionHandler()
        }

        guard !arguments.isEmpty, let command = commands.filter({$0.name == arguments[0]}).first else {
            print(shortHelp)
            errorHandler()
        }
    }

    // MARK: - Private Functions

}


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

        > horizon-cli shares rm QmSomeHash

      SUBCOMMANDS
        horizon-cli shares help                             - Displays detailed help information
        horizon-cli shares add <contact-name> <file>        - Adds a new file to be shared with a contact
        horizon-cli shares ls [<contact-name>]              - Lists all shared files (optionally for a given contact)
        horizon-cli shares rm <contact-name> <file-hash>    - Removes a file which was shared with a contact

        Use 'horizon-cli shares <subcmd> --help' for more information about each command.

    """

    private let shortHelp = """
    USAGE
      horizon-cli shares - Share files with Horizon contacts

    SYNOPSIS
      horizon-cli shares

      SUBCOMMANDS
        horizon-cli shares help                             - Displays detailed help information
        horizon-cli shares add <contact-name> <file>        - Adds a new file to be shared with a contact
        horizon-cli shares ls [<contact-name>]              - Lists all shared files (optionally for a given contact)
        horizon-cli shares rm <contact-name> <file-hash>    - Removes a file which was shared with a contact

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
              'horizon-cli shares rm <contact-name> <file-hash>' unshares a file with
              the given contact, and if the file is shared with no other contacts
              - removes the file from IPFS.

              Note that unsharing a file is not a security mechanism. There is no
              guarantee that your contact will receive the updated file list sans
              the removed file, or that the contact could not simply access the file
              via its direct IPFS hash.

                > horizon-cli shares rm QmSomeHash

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

        let commandArguments = Array(arguments.dropFirst())
        if !command.allowableNumberOfArguments.contains(commandArguments.count) {
            print(command.help)
            errorHandler()
        }

        switch command.name {
        case "add":
            let contact = commandArguments[0]
            let file = commandArguments[1]

            shareFile(file, with: contact)
        case "rm":
            let contact = commandArguments[0]
            let fileHash = commandArguments[1]

            unshareFile(fileHash, with: contact)
        default:
            print(command.help)
            errorHandler()
        }
    }

    // MARK: - Private Functions

    private func shareFile(_ file: String, with contactName: String) {
        guard let contact = model.contact(named: contactName) else {
            print("Contact does not exist.")
            self.errorHandler()
        }

        let fileURL = URL(fileURLWithPath: (file as NSString).expandingTildeInPath).standardized

        firstly {
            return model.shareFiles([fileURL], with: contact)
        }.then { contact in
            self.completionHandler()
        }.catch { error in
            if case HorizonError.shareOperationFailed(let reason) = error {
                if case .fileDoesNotExist(let file) = reason {
                    print("\(file): No such file or directory.")
                    self.errorHandler()
                }
                if case .sendAddressNotSet = reason {
                    print("\(contactName): No send address set. Cannot share files.")
                    self.errorHandler()
                }
            }

            print("Failed to share file. Is IPFS running?")
            self.errorHandler()
        }
    }

    private func unshareFile(_ fileHash: String, with contactName: String) {
        guard let contact = model.contact(named: contactName) else {
            print("Contact does not exist.")
            self.errorHandler()
        }

        guard let file = contact.sendList.files.filter({ $0.hash == fileHash }).first else {
            print("File does not exist.")
            self.errorHandler()
        }

        firstly {
            return model.unshareFiles([file], with: contact)
        }.then { contact in
            self.completionHandler()
        }.catch { error in
            if case HorizonError.shareOperationFailed(let reason) = error {
                if case .sendAddressNotSet = reason {
                    print("\(contactName): No send address set. Cannot unshare files.")
                    self.errorHandler()
                }
            }

            print("Failed to share file. Is IPFS running?")
            self.errorHandler()
        }
    }

}

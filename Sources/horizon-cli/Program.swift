//
//  Program.swift
//  horizon-cli
//
//  Created by Connor Power on 22.01.18.
//  Copyright © 2018 Semantical GmbH & Co. KG. All rights reserved.
//

import Foundation
import HorizonCore

/**
 In the absensce of any required program structure enforced by
 the `main.swift` file, the `Program` struct serves as a unified
 place to consolidate core program control - i.e. delegation to
 handlers, program exit on success or failure and run-loop
 management.
 */
struct Program {

    // MARK: - Properties

    let help = """
    USAGE
      horizon-cli - An encrypted fileshare for the decentralized web.

    SYNOPSIS
      horizon-cli [--help | -h] <command> ...

    OPTIONS

      --help, -h      - Show the full command help text.

    SUBCOMMANDS
      BASIC COMMANDS
        help                                    Prints this help menu
        sync                                    Syncs the receive lists from all contacts
        stat                                    Prints statistics

      CONTACT COMMANDS
        contacts add <name>                     Create a new contact
        contacts ls                             List all contacts
        contacts info <name>                    Prints contact and associated details
        contacts rm <name>                      Removes contact
        contacts rename <name> <new-name>       Renames contact
        contacts set-rcv-addr <name> <hash>     Sets the receive address for a contact

      SHARE COMMANDS
        shares help                             Displays detailed help information
        shares add <contact-name> <file>        Adds a new file to be shared with a contact
        shares ls [<contact-name>]              Lists all shared files (optionally for a given contact)
        shares rm <contact-name> <file-hahs>    Removes a file which was shared with a contact

      Use 'horizon-cli <command> --help' to learn more about each command.

    EXIT STATUS

      The CLI will exit with one of the following values:

      0     Successful execution.
      1     Failed executions.

    """

    let model: Model = Model(api: IPFSWebserviceAPI(logProvider: Loggers()),
                             persistentStore: UserDefaultsStore(),
                             eventCallback: nil)

    // MARK: - Functions

    /**
     The program's main function à la C. Unlike a C program however,
     the main function must be called manually.

     This function will spin up a run loop until all internal
     processing has completed.
     */
    func main() {
        let arguments: [String]
        if CommandLine.arguments.count == 1 {
            print("> ", separator: "", terminator: "")
            arguments = readLine(strippingNewline: true)?.split(separator: " ").map({String($0)}) ?? [String]()
        } else {
            arguments = Array(CommandLine.arguments.dropFirst())
        }

        guard arguments.count >= 1 else {
            print(help)
            exit(EXIT_FAILURE)
        }

        let command = arguments[0]
        let commandArgs = Array(arguments.dropFirst())

        switch command {
        case "contacts":
            ContactsHandler(model: model,
                            arguments: commandArgs,
                            completion: { exit(EXIT_SUCCESS) },
                            error: { exit(EXIT_FAILURE) }).run()
        case "shares":
            SharesHandler(model: model,
                            arguments: commandArgs,
                            completion: { exit(EXIT_SUCCESS) },
                            error: { exit(EXIT_FAILURE) }).run()
        case "-h", "--help", "help":
            print(help)
            exit(EXIT_SUCCESS)
        default:
            print(help)
            exit(EXIT_FAILURE)
        }

        dispatchMain()
    }

}

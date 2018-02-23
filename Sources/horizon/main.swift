//
//  main.swift
//  horizon
//
//  Created by Connor Power on 22.01.18.
//  Copyright © 2018 Semantical GmbH & Co. KG. All rights reserved.
//


import Foundation
import HorizonCore
import IPFSWebService

/**
 In the absensce of any required program structure enforced by
 the `main.swift` file, the `Program` struct serves as a unified
 place to consolidate core program control - i.e. delegation to
 handlers, program exit on success or failure and run-loop
 management.
 */
class Program {

    // MARK: - Properties

    let help = """
    USAGE
      horizon - An encrypted fileshare for the decentralized web.

    SYNOPSIS
      horizon [--help | -h] [--identity=<identity>] <command> ...

    IDENTITIES
      Horizon allows for multiple independent 'identities'. Each is namespaced
      with it's own list of contacts, shares and entirely separate version of
      IPFS. If no entity is provided, horizon will default to the 'default'
      entity – this is effectively the same as having provided `--identity=default`
      as a comand line option.

    OPTIONS
      --identity                                Use a self-contained and indepenedent identity other than 'default'
      --help, -h                                Show the full command help text.

    SUBCOMMANDS
      BASIC COMMANDS
        help                                    Prints this help menu
        sync                                    Syncs the receive lists from all contacts

      DAEMON COMMANDS
        daemon help                             Displays detailed help information
        daemon start                            Starts the horizon daemon in the background
        daemon status                           Prints the current status of the background daemon
        daemon ls                               Lists the status of the daemons for each identity
        daemon stop                             Starts the horizon daemon in the background

      CONTACT COMMANDS
        contacts help                           Displays detailed help information
        contacts add <name>                     Create a new contact
        contacts ls                             List all contacts
        contacts info [<name>]                  Prints contact and associated details
        contacts rm <name>                      Removes contact
        contacts rename <name> <new-name>       Renames contact
        contacts set-rcv-addr <name> <hash>     Sets the receive address for a contact

      SHARE COMMANDS
        shares help                             Displays detailed help information
        shares add <contact-name> <file>        Adds a new file to be shared with a contact
        shares ls [<contact-name>]              Lists all shared files (optionally for a given contact)
        shares rm <contact-name> <file-hahs>    Removes a file which was shared with a contact

      FILE COMMANDS
        files help                              Displays detailed help information
        files ls [<contact-name>]               Lists all received files (optionally from a given contact)
        files cat <hash>                        Outputs the contents of a file to the command line
        files cp <hash> <target-file>           Copies a shared file to a given location on the local machine

      Use 'horizon <command> --help' to learn more about each command.

    EXIT STATUS

      The CLI will exit with one of the following values:

      0     Successful execution.
      1     Failed executions.

    """

    var model: Model!

    // MARK: - Functions

    /**
     The program's main function à la C. Unlike a C program however,
     the main function must be called manually.

     This function will spin up a run loop until all internal
     processing has completed.
     */
    func main() {
        if !DaemonManager().isIPFSPresent {
            print("Required dependency IPFS not found. Please install with `brew install ipfs`")
            exit(EXIT_FAILURE)
        }

        var arguments: [String]
        if CommandLine.arguments.count == 1 {
            print("> ", separator: "", terminator: "")
            arguments = readLine(strippingNewline: true)?.split(separator: " ").map({String($0)}) ?? [String]()
        } else {
            arguments = Array(CommandLine.arguments.dropFirst())
        }

        var identity = "default"

        if ["-h", "--help", "help"].contains(arguments[0]) {
            print(help)
            exit(EXIT_SUCCESS)
        }

        if arguments[0].hasPrefix("--identity") {
            let splitString = arguments[0].split(separator: "=")

            guard splitString.count == 2 else {
                print(help)
                exit(EXIT_FAILURE)
            }

            identity = String(splitString[1])
            arguments = Array(arguments[1..<arguments.count])
        }

        let horizonDirectory = URL(fileURLWithPath: ("~/.horizon" as NSString).expandingTildeInPath)
        let config = Configuration(horizonDirectory: horizonDirectory, identity: identity)
        SwaggerClientAPI.basePath = config.apiBasePath
        model = Model(api: IPFSWebserviceAPI(logProvider: Loggers()),
                      config: config,
                      persistentStore: UserDefaultsStore(config: config),
                      eventCallback: nil)

        switch DaemonManager().status(for: config) {
        case .pidFilePresentButDaemonNotRunning(_), .stopped:
            print("Horizon daemon not running. Starting...")
            do {
                try DaemonManager().startDaemon(for: config)
            } catch {
                print("Failed to start daemon.")
                exit(EXIT_FAILURE)
            }
            let identityNotice = config.identity == "default" ? "" : "--identity=\(config.identity) "
            print("⚠️ Started. Remember to stop the daemon with 'horizon \(identityNotice)daemon stop'.")
        default:
            break
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
                            config: config,
                            arguments: commandArgs,
                            completion: { exit(EXIT_SUCCESS) },
                            error: { exit(EXIT_FAILURE) }).run()
        case "shares":
            SharesHandler(model: model,
                          config: config,
                          arguments: commandArgs,
                          completion: { exit(EXIT_SUCCESS) },
                          error: { exit(EXIT_FAILURE) }).run()
        case "files":
            FilesHandler(model: model,
                         config: config,
                         arguments: commandArgs,
                         completion: { exit(EXIT_SUCCESS) },
                         error: { exit(EXIT_FAILURE) }).run()
        case "daemon":
            DaemonHandler(model: model,
                          config: config,
                          arguments: commandArgs,
                          completion: { exit(EXIT_SUCCESS) },
                          error: { exit(EXIT_FAILURE) }).run()
        case "sync":
            SyncHandler(model: model,
                        config: config,
                        arguments: commandArgs,
                        completion: { exit(EXIT_SUCCESS) },
                        error: { exit(EXIT_FAILURE) }).run()
        default:
            print(help)
            exit(EXIT_FAILURE)
        }

        dispatchMain()
    }

}

Program().main()

//
//  Program.swift
//  horizon-cli
//
//  Created by Connor Power on 22.01.18.
//  Copyright © 2018 Semantical GmbH & Co. KG. All rights reserved.
//

import Foundation
import HorizonCore
import IPFSWebService
import Darwin


/**
 In the absensce of any required program structure enforced by
 the `main.swift` file, the `Program` struct serves as a unified
 place to consolidate core program control - i.e. delegation to
 handlers, program exit on success or failure and run-loop
 management.
 */
class Program {

    // MARK: - IPFSConfiguration

    struct IPFSConfiguration {
        let instanceNumber: Int
        let path: String
        let apiPort: Int
        let gatewayPort: Int
        let swarmPort: Int
        let apiBasePath: String

        init(instanceNumber: Int) {
            self.instanceNumber = instanceNumber
            self.path = "~/.horizon/instance\(instanceNumber)"
            self.apiPort = 5001 + instanceNumber
            self.gatewayPort = 8080 + instanceNumber
            self.swarmPort = 4001 + instanceNumber
            self.apiBasePath = "http://127.0.0.1:\(5001 + instanceNumber)/api/v0"
        }
    }

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
        daemon                                  Starts the horizon daemon
        sync                                    Syncs the receive lists from all contacts

      CONTACT COMMANDS
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
        let config = IPFSConfiguration(instanceNumber: 1)
        SwaggerClientAPI.basePath = config.apiBasePath

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
        case "files":
            FilesHandler(model: model,
                         arguments: commandArgs,
                         completion: { exit(EXIT_SUCCESS) },
                         error: { exit(EXIT_FAILURE) }).run()
        case "daemon":
            startDaemon(instanceNumber: 1)
        case "-h", "--help", "help":
            print(help)
            exit(EXIT_SUCCESS)
        default:
            print(help)
            exit(EXIT_FAILURE)
        }

        dispatchMain()
    }

    // MARK: - Private Functions

    private func ipfsCommand(for config: IPFSConfiguration) -> Process {
        var environment = ProcessInfo().environment
        environment["IPFS_PATH"] = config.path

        let task = Process()
        task.environment = environment
        return task
    }

    private func startDaemon(instanceNumber instance: Int = 1) {
        let config = IPFSConfiguration(instanceNumber: instance)

        let configDir = URL(fileURLWithPath: (config.path as NSString).expandingTildeInPath).deletingLastPathComponent()
        var isDir: ObjCBool = ObjCBool(false)
        if !FileManager.default.fileExists(atPath: configDir.absoluteString, isDirectory: &isDir) {
            try! FileManager.default.createDirectory(at: configDir, withIntermediateDirectories: true, attributes: nil)

            let initialize = ipfsCommand(for: config)
            initialize.launchPath = "/usr/local/bin/ipfs"
            initialize.arguments = ["init"]
            initialize.launch()
            initialize.waitUntilExit()
            guard initialize.terminationStatus == 0 else {
                fatalError("Failed to initialize IPFS instance")
            }

            let configAPI = ipfsCommand(for: config)
            configAPI.launchPath = "/usr/local/bin/ipfs"
            configAPI.arguments = ["config", "Addresses.API", "/ip4/127.0.0.1/tcp/\(config.apiPort)"]
            configAPI.launch()
            configAPI.waitUntilExit()
            guard configAPI.terminationStatus == 0 else {
                fatalError("Failed to configure IPFS API address")
            }

            let configGateway = ipfsCommand(for: config)
            configGateway.launchPath = "/usr/local/bin/ipfs"
            configGateway.arguments = ["config", "Addresses.Gateway" ,"/ip4/127.0.0.1/tcp/\(config.gatewayPort)"]
            configGateway.launch()
            configGateway.waitUntilExit()
            guard configGateway.terminationStatus == 0 else {
                fatalError("Failed to configure IPFS gateway address")
            }

            let configSwarm = ipfsCommand(for: config)
            configSwarm.launchPath = "/usr/local/bin/ipfs"
            configSwarm.arguments = ["config", "--json", "Addresses.Swarm", "[\"/ip4/0.0.0.0/tcp/\(config.swarmPort)\", \"/ip6/::/tcp/\(config.swarmPort)\"]"]
            configSwarm.launch()
            configSwarm.waitUntilExit()
            guard configSwarm.terminationStatus == 0 else {
                fatalError("Failed to configure IPFS swarm addresses")
            }
        }

        var group = setsid()
        if group == -1 {
            print("setsid() == -1")
            group = getpgrp()
        }

        let daemonProcess = ipfsCommand(for: config)
        daemonProcess.launchPath = "/usr/local/bin/ipfs"
        daemonProcess.arguments = ["daemon"]

        if setpgid(daemonProcess.processIdentifier, group) == -1 {
            print("unable to put task into same group as self: errno = %i", errno)
        }

        daemonProcess.launch()
    }

}

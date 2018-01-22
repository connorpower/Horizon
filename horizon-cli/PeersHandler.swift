//
//  PeersHandler.swift
//  horizon-cli
//
//  Created by Connor Power on 22.01.18.
//  Copyright © 2018 Semantical GmbH & Co. KG. All rights reserved.
//

import Foundation

/**
 A handler for all peer commands. Currently these are:

     $ horizon-cli peers list
     $ horizon-cli peers add {peer-name}
     $ horizon-cli peers remove {peer-name}
     $ horizon-cli peers edit {peer-name}

 */
class PeersHandler: Handler {

    // MARK: - Properties

    private let arguments: [String]

    private let completionHandler: () -> Void

    private let commands = [
        Command(command: "list", expectedNumArgs: 0, help: """
            horizon-cli peers list:
              Lists all peers which have been added to Horizon.
              This command takes no arguments.
            """)
    ]

    // MARK: - Handler Protocol

    required init(arguments: [String], completion: @escaping () -> Void) {
        self.arguments = arguments
        self.completionHandler = completion
    }

    func run() {
        guard !arguments.isEmpty else {
            printHelp()
            completionHandler()
            return
        }

        var matchedCommand: Command?
        for command in commands {
            if arguments.first == command.command {
                matchedCommand = command
                break
            }
        }

        if let matchedCommand = matchedCommand {
            print(matchedCommand.help)
        } else {
            printHelp()
        }
    }

    // MARK: - Private Functions

    private func printHelp() {
        print("No matched commands. Print help...")
    }

}

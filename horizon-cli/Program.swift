//
//  Program.swift
//  horizon-cli
//
//  Created by Connor Power on 22.01.18.
//  Copyright © 2018 Semantical GmbH & Co. KG. All rights reserved.
//

import Foundation

/**
 In the absensce of any required program structure enforced by
 the `main.swift` file, the `Program` struct serves as a unified
 place to consolidate core program control - i.e. delegation to
 handlers, program exit on success or failure and run-loop
 management.
 */
struct Program {

    // MARK: - Functions

    /**
     The program's main function à la C. Unlike a C program however,
     the main function must be called manually.

     This function will spin up a run loop until all internal
     processing has completed.
     */
    func main() {
        guard CommandLine.arguments.count >= 2 else {
            printHelp()
            exit(EXIT_FAILURE)
        }

        let command = CommandLine.arguments[1]
        let commandArgs = Array(CommandLine.arguments[2..<CommandLine.arguments.count])

        switch command {
        case "peers":
            PeersHandler(arguments: commandArgs, completion: { exit(EXIT_SUCCESS) }).run()
        default:
            printHelp()
            exit(EXIT_FAILURE)
        }
    }

    // MARK: - Private Functions

    private func printHelp() {
        print("Print help...")
    }

}

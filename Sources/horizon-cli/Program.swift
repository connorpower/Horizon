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

    let model: Model = Model(api: IPFSWebserviceAPI(logProvider: Loggers()), eventCallback: nil)

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
            printHelp()
            exit(EXIT_FAILURE)
        }

        let command = arguments[0]
        let commandArgs = Array(arguments[1..<arguments.count])

        switch command {
        case "contacts":
            ContactsHandler(model: model,
                         arguments: commandArgs,
                         completion: { exit(EXIT_SUCCESS) },
                         error: { exit(EXIT_FAILURE) }).run()
        default:
            printHelp()
            exit(EXIT_FAILURE)
        }

        dispatchMain()
    }

    // MARK: - Private Functions

    private func printHelp() {
        print("Print help...")
    }

}

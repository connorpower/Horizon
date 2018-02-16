//
//  Handler.swift
//  horizon-cli
//
//  Created by Connor Power on 22.01.18.
//  Copyright © 2018 Semantical GmbH & Co. KG. All rights reserved.
//

import Foundation
import HorizonCore

/**
 The CLI program has multiple top level commands, for instance:

     $ horizon-cli sync
     $ horizon-cli contacts list
     $ horizon-cli share "Max Mustermann" ~/Desktop/The\ Cathedral\ and\ the\ Bazaar.pdf

 In these examples above, there are three top level commands: `sync`,
 `contacts` and `share`. Each top level command has its own Handler which
 is repsonsible for processing the command.

 ## Examples

 Sync:

     $ horizon-cli sync
     Handler -> SyncHandler
     args -> []

 Contacts:

     $ horizon-cli contacts list
     Handler -> ContactsHandler
     args -> ["list"]

 Share:

     $ horizon-cli share "Max Mustermann" ~/Desktop/The\ Cathedral\ and\ the\ Bazaar.pdf
     Handler -> ShareHandler
     args -> ["Max Mustermann", "~/Desktop/The Cathedral and the Bazaar.pdf"]

 */
protocol Handler {

    /**
     Required initializer for a command handler.

     - parameter model: The dependency injected model.
     - parameter config: The configuration used for this particular run
     of the command line tool.
     - parameter arguments: All remaining command line arguments, excluding
     the name of the top-level command itself.
     - parameter completion: A completion block to be called when the
     command has been processed. The app will block on a run loop until
     this completion block is called.
     - parameter error: An error block to be called when the
     command has been unable to complete sucessfully. The app will block
     on a run loop until this completion block is called.
     */
    init(model: Model, config: ConfigurationProvider, arguments: [String],
         completion: @escaping () -> Never, error: @escaping () -> Never)

    /**
     Run the command handler as appopriate, calling the completion
     handler when finished.
     */
    func run()

}

//
//  Command.swift
//  horizon-cli
//
//  Created by Connor Power on 22.01.18.
//  Copyright © 2018 Semantical GmbH & Co. KG. All rights reserved.
//

import Foundation

/**
 A simple encapsulation of a command, as received on
 the command line.
 */
struct Command {

    /**
     The name of the command. In the case of
     `$ horizon-cli contacts list`, the command would
     be `"list"`.
     */
    let name: String

    /**
     The expected number of arguments for the command.
     In the case of `$ horizon-cli contacts list`, the
     expected number of argumnets would be `0`.
     */
    let expectedNumArgs: Int

    /**
     The help string, as it would be output to the terminal
     in the event that the user inputs invalid information.
     In the case of `$ horizon-cli contacts list foobar`, the
     output could be expected to be:

         horizon-cli contacts list:
           Lists all contacts which have been added to Horizon.
           This command takes no arguments.

     */
    let help: String

}

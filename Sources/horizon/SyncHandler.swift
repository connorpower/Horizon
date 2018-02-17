//
//  SyncHandler.swift
//  horizon
//
//  Created by Connor Power on 16.02.18.
//

import Foundation
import HorizonCore
import PromiseKit

struct SyncHandler: Handler {

    // MARK: - Constants

    let longHelp = """
    USAGE
      horizon sync - Sync the shared files from horizon contacts

    SYNOPSIS
      horizon sync

    DESCRIPTION

      'horizon sync' syncs the lists of shared files from your horizon
      contacts. Until this command is run, the newly shared files from
      other contacts are not visible in the local horizon instance.

      Note that a sync can take some quite some time. It's also important
      that your contacts are online and connected to a network.

      SUBCOMMANDS
        horizon sync help    - Displays detailed help information
        horizon sync         - Sync the shared files from horizon contacts

        Use 'horizon sync <subcmd> --help' for more information about each command.

    """

    private let shortHelp = """
    USAGE
      horizon sync - Sync the shared files from horizon contacts

    SYNOPSIS
      horizon sync

      SUBCOMMANDS
        horizon sync help    - Displays detailed help information
        horizon sync         - Sync the shared files from horizon contacts

        Use 'horizon sync <subcmd> --help' for more information about each command.

    """

    private let commands = [
        Command(name: "sync", allowableNumberOfArguments: [0], help: """
            horizon sync
              'horizon sync' syncs the lists of shared files from your horizon
              contacts. Until this command is run, the newly shared files from
              other contacts are not visible in the local horizon instance.

              Note that a sync can take some quite some time. It's also important
              that your contacts are online and connected to a network.

            """),
    ]

    // MARK: - Properties

    private let model: Model
    private let config: ConfigurationProvider

    private let arguments: [String]

    private let completionHandler: () -> Never
    private let errorHandler: () -> Never

    // MARK: - Handler Protocol

    init(model: Model, config: ConfigurationProvider, arguments: [String],
         completion: @escaping () -> Never, error: @escaping () -> Never) {
        self.model = model
        self.config = config
        self.arguments = arguments
        self.completionHandler = completion
        self.errorHandler = error
    }

    func run() {
        if !arguments.isEmpty, ["help", "-h", "--help"].contains(arguments[0]) {
            print(longHelp)
            completionHandler()
        }

        sync()
    }

    // MARK: - Private Functions

    private func sync() {
        firstly {
            model.sync()
        }.then { _ in
            // TODO: Print changes
            self.completionHandler()
        }.catch { error in
            print("Failed to sync. Have you started the horizon daemon?")
            self.errorHandler()
        }
    }

}

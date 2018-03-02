//
//  SyncHandler.swift
//  horizon
//
//  Created by Connor Power on 16.02.18.
//  Copyright © 2018 Connor Power. All rights reserved.
//

import Foundation
import HorizonCore
import PromiseKit

struct SyncHandler: Handler {

    // MARK: - Constants

    private let commands = [
        Command(name: "sync", allowableNumberOfArguments: [0], requiresRunningDaemon: true, help: """
            horizon sync
              'horizon sync' syncs the lists of shared files from your horizon
              contacts. Until this command is run, the newly shared files from
              other contacts are not visible in the local horizon instance.

                   > horizon sync
                   🌏 syncing...
                   contact-x: synced
                   contact-y: failed (receive address not set)
                   contact-z: synced

                   Set a receive address using `horizon contacts set-rcv-addr <contact-name> <receive-hash>`

              Note that a sync can take some quite some time. It's also important
              that your contacts are online and connected to a network.

            """)
    ]

    // MARK: - Properties

    private let model: Model
    private let configuration: ConfigurationProvider

    private let arguments: [String]

    private let completionHandler: () -> Never
    private let errorHandler: () -> Never

    // MARK: - Handler Protocol

    init(model: Model, configuration: ConfigurationProvider, arguments: [String],
         completion: @escaping () -> Never, error: @escaping () -> Never) {
        self.model = model
        self.configuration = configuration
        self.arguments = arguments
        self.completionHandler = completion
        self.errorHandler = error
    }

    func run() {
        if !arguments.isEmpty, ["help", "-h", "--help"].contains(arguments[0]) {
            print(SyncHelp.longHelp)
            completionHandler()
        }

        let isDaemonAutostarted = DaemonManager().startDaemonIfNecessary(configuration)

        func onCompletion(_ success: Bool) -> Never {
            if isDaemonAutostarted {
                DaemonManager().stopDaemonIfNecessary(configuration)
            }
            success ? completionHandler() : errorHandler()
        }

        guard arguments.count == 0 else {
            print(SyncHelp.shortHelp)
            onCompletion(false)
        }

        sync(completion: onCompletion)
    }

    // MARK: - Private Functions

    private func sync(completion: @escaping (Bool) -> Never) {
        print("🌏 syncing...")

        func paddedContactPrefix(_ contact: Contact, padLength: Int) -> String {
            return "\(contact.displayName):".padding(toLength: padLength + 1, withPad: " ", startingAt: 0)
        }

        let longestContactName = model.contacts.reduce(0) { result, contact in
            return contact.displayName.count > result ? contact.displayName.count : result
        }

        firstly {
            model.sync()
        }.then { syncStates in
            var wasAReceiveAddressMissing = false

            for syncState in syncStates {
                if case .synced(let contact, _) = syncState {
                    let paddedName = paddedContactPrefix(contact, padLength: longestContactName)
                    print("\(paddedName) synced")
                } else if case .failed(let contact, let error) = syncState {
                    let paddedName = paddedContactPrefix(contact, padLength: longestContactName)
                    if case HorizonError.syncOperationFailed(let reason) = error {
                        switch reason {
                        case .failedToRetrieveSharedFileList:
                            print("\(paddedName) failed (contact most likely offline)")
                        case .receiveAddressNotSet:
                            wasAReceiveAddressMissing = true
                            print("\(paddedName) failed (receive address not set)")
                        default:
                            print("\(paddedName) failed (unknown error)")
                        }
                    } else {
                        print("\(paddedName) failed (unknown error)")
                    }
                }
            }

            if wasAReceiveAddressMissing {
                print("\nSet a receive address using `horizon contacts set-rcv-addr <contact-name> <receive-hash>`")
            }
            completion(true)
        }.catch { _ in
            print("Failed to sync – most likely due to a timeout. Try again.")
            completion(false)
        }
    }

}

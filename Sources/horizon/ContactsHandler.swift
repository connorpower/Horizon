//
//  ContactsHandler.swift
//  horizon
//
//  Created by Connor Power on 22.01.18.
//  Copyright © 2018 Semantical GmbH & Co. KG. All rights reserved.
//

import Foundation
import HorizonCore
import PromiseKit

struct ContactsHandler: Handler {

    // MARK: - Constants

    private let commands = [
        Command(name: "add", allowableNumberOfArguments: [1], requiresRunningDaemon: true,
                help: ContactsHelp.commandAddHelp),
        Command(name: "ls", allowableNumberOfArguments: [0], requiresRunningDaemon: false,
                help: ContactsHelp.commandLsHelp),
        Command(name: "info", allowableNumberOfArguments: [0, 1], requiresRunningDaemon: false,
                help: ContactsHelp.commandInfoHelp),
        Command(name: "rm", allowableNumberOfArguments: [1], requiresRunningDaemon: true,
                help: ContactsHelp.commandRmHelp),
        Command(name: "rename", allowableNumberOfArguments: [2], requiresRunningDaemon: true,
                help: ContactsHelp.commandRenameHelp),
        Command(name: "set-rcv-addr", allowableNumberOfArguments: [2], requiresRunningDaemon: false,
                help: ContactsHelp.commandSetRcvAddrHelp)
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
            print(ContactsHelp.longHelp)
            completionHandler()
        }

        guard !arguments.isEmpty, let command = commands.filter({$0.name == arguments[0]}).first else {
            print(ContactsHelp.shortHelp)
            errorHandler()
        }

        let commandArguments = Array(arguments.dropFirst())
        if !command.allowableNumberOfArguments.contains(commandArguments.count) {
            print(command.help)
            errorHandler()
        }

        runCommand(command, arguments: commandArguments)
    }

    // MARK: - Private Functions

    private func runCommand(_ command: Command, arguments: [String]) {
        let isDaemonAutostarted = command.requiresRunningDaemon && DaemonManager().startDaemonIfNecessary(configuration)

        func onCompletion(_ success: Bool) -> Never {
            if isDaemonAutostarted {
                DaemonManager().stopDaemonIfNecessary(configuration)
            }
            success ? completionHandler() : errorHandler()
        }

        switch command.name {
        case "add":
            addContact(name: arguments[0], completion: onCompletion)
        case "ls":
            listContacts(completion: onCompletion)
        case "info":
            listContactInfo(for: ContactFilter(optionalContact: arguments.first), completion: onCompletion)
        case "rm":
            removeContact(name: arguments[0], completion: onCompletion)
        case "rename":
            renameContact(arguments[0], to: arguments[1], completion: onCompletion)
        case "set-rcv-addr":
            setReceiveAddress(of: arguments[0], to: arguments[1], completion: onCompletion)
        default:
            print(command.help)
            onCompletion(false)
        }
    }

    private func addContact(name: String, completion: @escaping (Bool) -> Never) {
        firstly {
            return model.addContact(name: name)
        }.then { contact in
            print("🤝 Send address: \(contact.sendAddress?.address ?? "nil")")
            completion(true)
        }.catch { error in
            if case HorizonError.contactOperationFailed(let reason) = error {
                if case .contactAlreadyExists = reason {
                    print("Contact already exists.")
                    completion(false)
                }
            }

            print("Failed to add contact.")
            completion(false)
        }
    }

    private func listContactInfo(for contactFilter: ContactFilter, completion: @escaping (Bool) -> Never) {
        let contacts: [Contact]

        switch contactFilter {
        case .specificContact(let name):
            guard let specificContact = model.contact(named: name) else {
                print("Contact does not exist.")
                completion(false)
            }
            contacts = [specificContact]
        case .allContacts:
            contacts = model.contacts
        }

        for contact in contacts {
            print("""
                \(contact.displayName)
                🤝 Send address:    \(contact.sendAddress?.address ?? "nil")
                🤝 Receive address: \(contact.receiveAddress ?? "nil")
                🔑 IPFS keypair:    \(contact.sendAddress?.keypairName ?? "nil")

                """)
        }
        completion(true)
    }

    private func listContacts(completion: @escaping (Bool) -> Never) {
        for contact in model.contacts {
            print(contact.displayName)
        }

        completion(true)
    }

    private func removeContact(name: String, completion: @escaping (Bool) -> Never) {
        firstly {
            model.removeContact(name: name)
        }.then {
            completion(true)
        }.catch { error in
            if case HorizonError.contactOperationFailed(let reason) = error {
                if case .contactDoesNotExist = reason {
                    print("Contact does not exist.")
                    completion(false)
                }
            }

            print("Failed to remove contact.")
            completion(false)
        }
    }

    private func renameContact(_ name: String, to newName: String, completion: @escaping (Bool) -> Never) {
        firstly {
            model.renameContact(name, to: newName)
        }.then { _ in
            completion(true)
        }.catch { error in
            if case HorizonError.contactOperationFailed(let reason) = error {
                if case .contactDoesNotExist = reason {
                    print("Contact does not exist.")
                    completion(false)
                } else if case .contactAlreadyExists = reason {
                    print("Another contact already exists with the name \(newName).")
                    completion(false)
                }
            }

           print("Failed to rename contact.")
           completion(false)
        }
    }

    private func setReceiveAddress(of name: String, to recieveAddress: String, completion: @escaping (Bool) -> Never) {
        guard let contact = model.contact(named: name) else {
            print("Contact does not exist.")
            completion(false)
        }

        model.updateReceiveAddress(for: contact, to: recieveAddress)
        completion(true)
    }

}

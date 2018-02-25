//
//  FilesHandler.swift
//  horizon
//
//  Created by Connor Power on 16.02.18.
//  Copyright © 2018 Semantical GmbH & Co. KG. All rights reserved.
//

import Foundation
import HorizonCore
import PromiseKit

struct FilesHandler: Handler {

    // MARK: - Constants

    private let commands = [
        Command(name: "share", allowableNumberOfArguments: [2], requiresRunningDaemon: true,
                help: FilesHelp.commandShareHelp),
        Command(name: "unshare", allowableNumberOfArguments: [2], requiresRunningDaemon: true,
                help: FilesHelp.commandUnshareHelp),
        Command(name: "ls", allowableNumberOfArguments: [0, 1], requiresRunningDaemon: false,
                help: FilesHelp.commandLsHelp),
        Command(name: "cat", allowableNumberOfArguments: [2], requiresRunningDaemon: true,
                help: FilesHelp.commandCatHelp),
        Command(name: "cp", allowableNumberOfArguments: [3], requiresRunningDaemon: true,
                help: FilesHelp.commandCpHelp)
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
            print(FilesHelp.longHelp)
            completionHandler()
        }

        guard !arguments.isEmpty, let command = commands.filter({$0.name == arguments[0]}).first else {
            print(FilesHelp.shortHelp)
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
        case "share":
            shareFile(arguments[1], with: arguments[0], completion: onCompletion)
        case "unshare":
            unshareFile(arguments[1], with: arguments[0], completion: onCompletion)
        case "ls":
            listReceivedFiles(for: ContactFilter(optionalContact: arguments.first), completion: onCompletion)
        case "cat":
            printData(contact: arguments[0], fileName: arguments[1], completion: onCompletion)
        case "cp":
            copyFile(contact: arguments[0], fileName: arguments[1], to: arguments[2], completion: onCompletion)
        default:
            print(command.help)
            onCompletion(false)
        }
    }

    private func listReceivedFiles(for contactFilter: ContactFilter, completion: @escaping (Bool) -> Never) {
        func printFileList(_ files: [File], prefix: String = "") {
            if files.isEmpty {
                print("\(prefix)(no files)")
            } else {
                for file in files {
                    print("\(prefix)\(file.name)")
                }
            }
        }

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
            print(contact.displayName)
            print("  sent:")
            printFileList(contact.sendList.files, prefix: "    📤 ")

            print("  received:")
            printFileList(contact.receiveList.files, prefix: "    📥 ")
            print("")
        }
        completion(true)
    }

    private func printData(contact: String, fileName: String, completion: @escaping (Bool) -> Never) {
        guard let contact = model.contact(named: contact) else {
            print("Contact does not exist.")
            completion(false)
        }

        guard let file = model.file(named: fileName, sentOrReceivedFrom: contact) else {
            print("No such file.")
            completion(false)
        }

        firstly {
            return model.data(for: file)
        }.then { data in
            var buffer: [UInt8] = []
            for byte in data {
                buffer.append(byte)
            }

            if fwrite(buffer, MemoryLayout<UInt8>.size, buffer.count, stdout) == 0 {
                print("Failed to write file")
            } else {
                fsync(fileno(stdout))
            }

            completion(true)
        }.catch { _ in
            print("Failed to retrieve file. Have you started the horizon daemon and is the contact online?")
            completion(false)
        }
    }

    private func copyFile(contact: String, fileName: String, to targetLocation: String,
                          completion: @escaping (Bool) -> Never) {
        guard let contact = model.contact(named: contact) else {
            print("Contact does not exist.")
            completion(false)
        }

        guard let file = model.file(named: fileName, sentOrReceivedFrom: contact) else {
            print("No such file.")
            completion(false)
        }

        let location = FileManager.default.finderStyleSafePath(for: file,
                                                               atProposedPath: URL(fileURLWithPath: targetLocation))

        firstly {
            return model.data(for: file)
        }.then { data in
            do {
                try data.write(to: location)
            } catch {
                print("\(location.path): Failed to write file")
            }
            completion(true)
        }.catch { _ in
            print("Failed to retrieve file. Have you started the horizon daemon and is the contact online?")
            completion(false)
        }
    }

    private func shareFile(_ file: String, with contactName: String, completion: @escaping (Bool) -> Never) {
        guard let contact = model.contact(named: contactName) else {
            print("Contact does not exist.")
            completion(false)
        }

        let fileURL = URL(fileURLWithPath: (file as NSString).expandingTildeInPath).standardized

        firstly {
            return model.shareFiles([fileURL], with: contact)
        }.then { _ in
            completion(true)
        }.catch { error in
            if case HorizonError.fileOperationFailed(let reason) = error {
                switch reason {
                case .fileDoesNotExist(let file):
                    print("\(file): No such file or directory.")
                    completion(false)
                case .sendAddressNotSet:
                    print("\(contactName): No send address set. Cannot share files.")
                    completion(false)
                case .fileAlreadyExists(let file):
                    print("\(file): File already exists. Use a different file name.")
                    completion(false)
                default:
                    break
                }
            }

            print("Failed to share file – most likely due to a timeout. Try again.")
            completion(false)
        }
    }

    private func unshareFile(_ fileHash: String, with contactName: String, completion: @escaping (Bool) -> Never) {
        guard let contact = model.contact(named: contactName) else {
            print("Contact does not exist.")
            completion(false)
        }

        guard let file = contact.sendList.files.filter({ $0.hash == fileHash }).first else {
            print("File does not exist.")
            completion(false)
        }

        firstly {
            return model.unshareFiles([file], with: contact)
        }.then { _ in
            completion(true)
        }.catch { error in
            if case HorizonError.fileOperationFailed(let reason) = error {
                if case .sendAddressNotSet = reason {
                    print("\(contactName): No send address set. Cannot unshare files.")
                    completion(false)
                }
            }

            print("Failed to share file – most likely due to a timeout. Try again.")
            completion(false)
        }
    }

}

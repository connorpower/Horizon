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
        Command(name: "cat", allowableNumberOfArguments: [1], requiresRunningDaemon: true,
                help: FilesHelp.commandCatHelp),
        Command(name: "cp", allowableNumberOfArguments: [2], requiresRunningDaemon: true,
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

        switch command.name {
        case "share":
            shareFile(arguments[1], with: arguments[0])
        case "unshare":
            unshareFile(arguments[1], with: arguments[0])
        case "ls":
            listReceivedFiles(for: ContactFilter(optionalContact: arguments.first))
        case "cat":
            printData(for: arguments[0])
        case "cp":
            copyFile(hash: arguments[0], to: arguments[1])
        default:
            print(command.help)
            errorHandler()
        }

        if isDaemonAutostarted {
            DaemonManager().stopDaemonIfNecessary(configuration)
        }
    }

    private func listReceivedFiles(for contactFilter: ContactFilter) {
        func printFileList(_ files: [File], indentation: String = "") {
            if files.isEmpty {
                print("\(indentation)(no files)")
            } else {
                for file in files {
                    print("\(indentation)\(file.hash ?? "nil"): \(file.name)")
                }
            }
        }

        let contacts: [Contact]

        switch contactFilter {
        case .specificContact(let name):
            guard let specificContact = model.contact(named: name) else {
                print("Contact does not exist.")
                errorHandler()
            }
            contacts = [specificContact]
        case .allContacts:
            contacts = model.contacts
        }

        for contact in contacts {
            print(contact.displayName)
            print("  sent:")
            printFileList(contact.sendList.files, indentation: "    ")

            print("  received:")
            printFileList(contact.receiveList.files, indentation: "    ")
            print("")
        }
        completionHandler()
    }

    private func printData(for hash: String) {
        guard let file = model.file(matching: hash) else {
            print("File does not exist.")
            self.errorHandler()
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

            self.completionHandler()
        }.catch { _ in
            print("Failed to retrieve file. Have you started the horizon daemon and is the contact online?")
            self.errorHandler()
        }
    }

    private func copyFile(hash: String, to targetLocation: String) {
        guard let file = model.file(matching: hash) else {
            print("File does not exist.")
            self.errorHandler()
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
            self.completionHandler()
        }.catch { _ in
            print("Failed to retrieve file. Have you started the horizon daemon and is the contact online?")
            self.errorHandler()
        }
    }

    private func shareFile(_ file: String, with contactName: String) {
        guard let contact = model.contact(named: contactName) else {
            print("Contact does not exist.")
            self.errorHandler()
        }

        let fileURL = URL(fileURLWithPath: (file as NSString).expandingTildeInPath).standardized

        firstly {
            return model.shareFiles([fileURL], with: contact)
        }.then { _ in
            self.completionHandler()
        }.catch { error in
            if case HorizonError.fileOperationFailed(let reason) = error {
                if case .fileDoesNotExist(let file) = reason {
                    print("\(file): No such file or directory.")
                    self.errorHandler()
                }
                if case .sendAddressNotSet = reason {
                    print("\(contactName): No send address set. Cannot share files.")
                    self.errorHandler()
                }
            }

            print("Failed to share file. Have you started the horizon daemon?")
            self.errorHandler()
        }
    }

    private func unshareFile(_ fileHash: String, with contactName: String) {
        guard let contact = model.contact(named: contactName) else {
            print("Contact does not exist.")
            self.errorHandler()
        }

        guard let file = contact.sendList.files.filter({ $0.hash == fileHash }).first else {
            print("File does not exist.")
            self.errorHandler()
        }

        firstly {
            return model.unshareFiles([file], with: contact)
        }.then { _ in
            self.completionHandler()
        }.catch { error in
            if case HorizonError.fileOperationFailed(let reason) = error {
                if case .sendAddressNotSet = reason {
                    print("\(contactName): No send address set. Cannot unshare files.")
                    self.errorHandler()
                }
            }

            print("Failed to share file. Have you started the horizon daemon?")
            self.errorHandler()
        }
    }

}

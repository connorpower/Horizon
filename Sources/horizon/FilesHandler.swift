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
        Command(name: "share", allowableNumberOfArguments: [2], help: """
            horizon files share <contact> <file>
              'horizon files share' adds a new file to be shared with a contact.
              The file will be added to IPFS. The list of files shared with the
              contacted will be updated and in turn also re-published to IPFS.

                > horizon files share mmusterman './The Byzantine Generals Problem.pdf'

            """),
        Command(name: "unshare", allowableNumberOfArguments: [2], help: """
            horizon files unshare <contact> <file>
              'horizon files unshare <contact> <hash>' unshares a file with
              the given contact, and if the file is shared with no other contacts
              - removes the file from IPFS.

              Note that unsharing a file is not a security mechanism. There is no
              guarantee that your contact will receive the updated file list sans
              the removed file, or that the contact could not simply access the file
              via its direct IPFS hash.

                > horizon files unshare QmSomeHash

            """),
        Command(name: "ls", allowableNumberOfArguments: [0, 1], help: """
            horizon files ls [<contact>]
              'horizon files ls [<contact>]' lists all files you have received,
              optionally restricted to a single contact.

                > horizon files ls
                mmusterman
                  sent
                    QmSomeHash - "The Byzantine Generals Problem.pdf"
                    QmSomeHash - "This is Water, David Foster Wallace.pdf"
                  received:
                    QmSomeHash - "IPFS - Content Addressed, Versioned, P2P File System (DRAFT 3).pdf"

                jbloggs
                  sent
                    (no files)
                  received
                    QmSomeHash: "Bitcoin: A Peer-to-Peer Electronic Cash System, Satoshi Nakamoto.pdf"

            """),
        Command(name: "cat", allowableNumberOfArguments: [1], help: """
            horizon files cat <hash>
              'horizon files cat <hash>' outputs the contents of a file to the
              command line. Care should be taken with binary files, as the shell may
              interpret byte sequences in unpredictable ways. Most useful combined with
              a pipe.

                > horizon files cat QmSomeHash | gzip > received_file.gzip

            """),
        Command(name: "cp", allowableNumberOfArguments: [2], help: """
            horizon files cp <hash> <target-file>
              'horizon files cp <hash> <target-file>' copies the contents of a
              received file to a given location on the local machine. If <target-file>
              is a directory, the actual file will be written with it's Horizon name
              inside the directory. The following command would copy a file from
              Horizon to your desktop.

                > horizon files cp QmSomeHash ~/Desktop

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

        switch command.name {
        case "share":
            shareFile(commandArguments[1], with: commandArguments[0])
        case "unshare":
            unshareFile(commandArguments[1], with: commandArguments[0])
        case "ls":
            listReceivedFiles(for: ContactFilter(optionalContact: commandArguments.first))
        case "cat":
            printData(for: commandArguments[0])
        case "cp":
            copyFile(hash: commandArguments[0], to: commandArguments[1])
        default:
            print(command.help)
            errorHandler()
        }
    }

    // MARK: - Private Functions

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
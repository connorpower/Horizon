//
//  FilesHandler.swift
//  horizon-cli
//
//  Created by Connor Power on 16.02.18.
//

import Foundation
import HorizonCore
import PromiseKit

struct FilesHandler: Handler {

    // MARK: - Constants

    let longHelp = """
    USAGE
      horizon-cli files - Manipulate files shared with you by Horizon contacts

    SYNOPSIS
      horizon-cli files

    DESCRIPTION

      'horizon-cli files ls [<contact-name>]' lists all files you have received,
      optionally restricted to a single contact.

        > horizon-cli files ls
        mmusterman
        QmSomeHash: "The Byzantine Generals Problem.pdf"
        QmSomeHash: "This is Water, David Foster Wallace.pdf"

        jbloggs
        QmSomeHash: "IPFS - Content Addressed, Versioned, P2P File System (DRAFT 3).pdf"

      You may optionally filter by only a given contact.

        > horizon-cli files ls jbloggs
        QmSomeHash: "IPFS - Content Addressed, Versioned, P2P File System (DRAFT 3).pdf"

      'horizon-cli files cat <hash>' outputs the contents of a file to the
      command line. Care should be taken with binary files, as the shell may
      interpret byte sequences in unpredictable ways. Most useful combined with
      a pipe.

        > horizon-cli files cat QmSomeHash | gzip > received_file.gzip

      'horizon-cli files cp <target-file>' copies the contents of a received file
      to a given location on the local machine. If <target-file> is a directory,
      the actual file will be written with it's Horizon name inside the directory.
      The following command would copy a file from Horizon onto your desktop.

        > horizon-cli files cp QmSomeHash ~/Desktop

      SUBCOMMANDS
        horizon-cli files help                       - Displays detailed help information
        horizon-cli files ls [<contact-name>]        - Lists all received files (optionally from a given contact)
        horizon-cli files cat <hash>                 - Outputs the contents of a file to the command line
        horizon-cli files cp <hash> <target-file>    - Copies a shared file to a given location on the local machine

        Use 'horizon-cli files <subcmd> --help' for more information about each command.

    """

    private let shortHelp = """
    USAGE
      horizon-cli files - Manipulate files shared with you by Horizon contacts

    SYNOPSIS
      horizon-cli files

      SUBCOMMANDS
        horizon-cli files help                       - Displays detailed help information
        horizon-cli files ls [<contact-name>]        - Lists all received files (optionally from a given contact)
        horizon-cli files cat <hash>                 - Outputs the contents of a file to the command line
        horizon-cli files cp <hash> <target-file>    - Copies a shared file to a given location on the local machine

        Use 'horizon-cli files <subcmd> --help' for more information about each command.

    """

    private let commands = [
        Command(name: "ls", allowableNumberOfArguments: [0, 1], help: """
            horizon-cli files ls [<contact-name>]
              'horizon-cli files ls [<contact-name>]' lists all files you have received,
              optionally restricted to a single contact.

                > horizon-cli files ls
                mmusterman
                QmSomeHash: "The Byzantine Generals Problem.pdf"
                QmSomeHash: "This is Water, David Foster Wallace.pdf"

                jbloggs
                QmSomeHash: "IPFS - Content Addressed, Versioned, P2P File System (DRAFT 3).pdf"

            """),
        Command(name: "cat", allowableNumberOfArguments: [1], help: """
            horizon-cli files cat <hash>
              'horizon-cli files cat <hash>' outputs the contents of a file to the
              command line. Care should be taken with binary files, as the shell may
              interpret byte sequences in unpredictable ways. Most useful combined with
              a pipe.

                > horizon-cli files cat QmSomeHash | gzip > received_file.gzip

            """),
        Command(name: "cp", allowableNumberOfArguments: [2], help: """
            horizon-cli files cp <hash> <target-file>
              'horizon-cli files cp <hash> <target-file>' copies the contents of a
              received file to a given location on the local machine. If <target-file>
              is a directory, the actual file will be written with it's Horizon name
              inside the directory. The following command would copy a file from
              Horizon to your desktop.

                > horizon-cli files cp QmSomeHash ~/Desktop

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

        guard !arguments.isEmpty, let command = commands.filter({$0.name == arguments[0]}).first else {
            print(shortHelp)
            errorHandler()
        }

        let commandArguments = Array(arguments.dropFirst())
        if !command.allowableNumberOfArguments.contains(commandArguments.count) {
            print(command.help)
            errorHandler()
        }

        switch command.name {
        case "ls":
            let contactFilter = ContactFilter(optionalContact: commandArguments.first)

            listReceivedFiles(for: contactFilter)
        case "cat":
            let hash = commandArguments[0]

            printData(for: hash)
        case "cp":
            let hash = commandArguments[0]
            let targetLocation = commandArguments[1]

            copyFile(hash: hash, to: targetLocation)
        default:
            print(command.help)
            errorHandler()
        }
    }

    // MARK: - Private Functions

    private func listReceivedFiles(for contactFilter: ContactFilter) {
        let contacts:[Contact]

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
            let files = contact.receiveList.files
            if files.isEmpty {
                print("(no files)")
            } else {
                for file in files {
                    print("\(file.hash ?? "nil"): \(file.name)")
                }
            }
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
            print(String(data: data, encoding: .utf8) ?? "<failed to cat>")
            self.completionHandler()
        }.catch { error in
            print("Failed to retrieve file. Have you started the horizon daemon and is the contact online?")
            self.errorHandler()
        }
    }

    private func copyFile(hash: String, to targetLocation: String) {
        guard let file = model.file(matching: hash) else {
            print("File does not exist.")
            self.errorHandler()
        }

        let targetLocation = (targetLocation as NSString).expandingTildeInPath
        let location: URL
        var isDir = ObjCBool(false)
        if !FileManager.default.fileExists(atPath: targetLocation, isDirectory: &isDir) {
            location = URL(fileURLWithPath: targetLocation)
        } else {
            var maybeLocation: URL?
            var counter = 1

            repeat {
                if isDir.boolValue {
                    let filename = file.name + (counter == 1 ? "" : " (\(counter.description))")
                    maybeLocation = URL(fileURLWithPath: targetLocation).appendingPathComponent(filename)
                } else {
                    let pathExtension = counter == 1 ? "" : " (\(counter.description))"
                    maybeLocation = URL(fileURLWithPath: targetLocation).appendingPathExtension(pathExtension)
                }
                counter += 1
            } while FileManager.default.fileExists(atPath: targetLocation)

            location = maybeLocation!
        }

        firstly {
            return model.data(for: file)
        }.then { data in
            do {
                try data.write(to: location)
            } catch {
                print("\(location.path): Failed to write file")
            }
            self.completionHandler()
        }.catch { error in
            print("Failed to retrieve file. Have you started the horizon daemon and is the contact online?")
            self.errorHandler()
        }
    }

}

//
//  DaemonHandler.swift
//  horizon
//
//  Created by Connor Power on 16.02.18.
//  Copyright © 2018 Semantical GmbH & Co. KG. All rights reserved.
//

import Foundation
import HorizonCore
import PromiseKit
import Darwin

struct DaemonHandler: Handler {

    // MARK: - Constants

    private let commands = [
        Command(name: "start", allowableNumberOfArguments: [0], requiresRunningDaemon: false,
                help: DaemonHelp.commandStartHelp),
        Command(name: "status", allowableNumberOfArguments: [0], requiresRunningDaemon: false,
                help: DaemonHelp.commandStatusHelp),
        Command(name: "stop", allowableNumberOfArguments: [0], requiresRunningDaemon: false,
                help: DaemonHelp.commandStopHelp),
        Command(name: "ls", allowableNumberOfArguments: [0], requiresRunningDaemon: false,
                help: DaemonHelp.commandLsHelp)
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
            print(DaemonHelp.longHelp)
            completionHandler()
        }

        guard !arguments.isEmpty, let command = commands.filter({$0.name == arguments[0]}).first else {
            print(DaemonHelp.shortHelp)
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
        case "start":
            startDaemon()
        case "status":
            printDaemonStatus()
        case "stop":
            stopDaemon()
        case "ls":
            listDaemons()
        default:
            print(command.help)
            errorHandler()
        }

        if isDaemonAutostarted {
            DaemonManager().stopDaemonIfNecessary(configuration)
        }
    }

    private func startDaemon() {
        do {
            try DaemonManager().startDaemon(for: configuration)
            print("Started 🤖")
        } catch {
            print("Failed to start daemon")
            errorHandler()
        }

        completionHandler()
    }

    private func printDaemonStatus() {
        printStatus(for: configuration, withIdentityPrefix: false)
        completionHandler()
    }

    private func listDaemons() {
        let maybeIdentites = try? FileManager.default.contentsOfDirectory(at: configuration.horizonDirectory,
                                                                          includingPropertiesForKeys: [.isDirectoryKey],
                                                                          options: .skipsSubdirectoryDescendants)

        guard let identities = maybeIdentites else {
            print("Identity 'default': Stopped 💀")
            errorHandler()
        }

        for identity in identities {
            let config = Configuration(horizonDirectory: self.configuration.horizonDirectory,
                                       identity: identity.lastPathComponent)
            printStatus(for: config, withIdentityPrefix: true)
        }

        completionHandler()
    }

    private func stopDaemon() {
        if DaemonManager().stopDaemon(for: configuration) {
            print("Stopped 💀")
            completionHandler()
        } else {
            print("Daemon not running")
            completionHandler()
        }
    }

    private func printStatus(for configuration: ConfigurationProvider, withIdentityPrefix: Bool = false) {
        let identityPrefix = withIdentityPrefix ? "Identity '\(configuration.identity)': " : ""

        switch DaemonManager().status(for: configuration) {
        case .running(let pid):
            print("\(identityPrefix)Running (PID: \(pid.description)) 🤖")
        case .stopped:
            print("\(identityPrefix)Stopped 💀")
        case .pidFilePresentButDaemonNotRunning(let pid):
            print("\(identityPrefix)Error (PID: \(pid.description) not running but PID file " +
                "remains at \(configuration.daemonPIDPath.path)) ⚠️")
        }
    }

}

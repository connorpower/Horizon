//
//  DaemonHandler.swift
//  horizon
//
//  Created by Connor Power on 16.02.18.
//

import Foundation
import HorizonCore
import PromiseKit
import Darwin

struct DaemonHandler: Handler {

    // MARK: - Constants

    let longHelp = """
    USAGE
      horizon daemon - Start or stop the background horizon process

    SYNOPSIS
      horizon daemon

    DESCRIPTION

      'horizon daemon start' starts the background daemon. The background
      daemon remains running so that contacts can access your shared files.

      The root directory for the daemon is located at `~/.horizon/<identity>`.
      If no particular identity was provided to horizon with the `--identity`
      flag, then the root for the daemon will be `~/.horizon/default`.

      If the daemon hangs for some reason, the PID can be found in written
      to a file at `~/.horizon/<identity>/PID`, from which you can issue a
      manual `kill` command.

        > horizon daemon start
        > horizon daemon status
        Running (PID: 12345)

        > horizon daemon stop
        > horizon daemon status
        Stopped

      'horizon daemon status' prints the status of the background daemon.
      'horizon daemon stop' stops the background daemon.

      'horizon daemon ls' lists the status of the daemon for each identity.

        > horizon daemon ls
        'default': Running (PID: 12345)
        'work': Running (PID: 67890)
        'test': Stopped

      SUBCOMMANDS
        horizon daemon help     - Displays detailed help information
        horizon daemon start    - Starts the horizon daemon in the background
        horizon daemon status   - Prints the current status of the background daemon
        horizon daemon ls       - Lists the status of the daemons for each identity
        horizon daemon stop     - Starts the horizon daemon in the background

        Use 'horizon daemon <subcmd> --help' for more information about each command.

    """

    private let shortHelp = """
    USAGE
      horizon daemon - Start or stop the background horizon process

    SYNOPSIS
      horizon daemon

      SUBCOMMANDS
        horizon daemon help     - Displays detailed help information
        horizon daemon start    - Starts the horizon daemon in the background
        horizon daemon status   - Prints the current status of the background daemon
        horizon daemon ls       - Lists the status of the daemons for each identity
        horizon daemon stop     - Starts the horizon daemon in the background

        Use 'horizon daemon <subcmd> --help' for more information about each command.

    """

    private let commands = [
        Command(name: "start", allowableNumberOfArguments: [0], help: """
            horizon daemon start
              'horizon daemon start' starts the background daemon.
              The background daemon remains running so that contacts can access your
              shared files.

              The root directory for the daemon is located at `~/.horizon/<identity>`.
              If no particular identity was provided to horizon with the `--identity`
              flag, then the root for the daemon will be `~/.horizon/default`.

              If the daemon hangs for some reason, the PID can be found in written
              to a file at `~/.horizon/<identity>/PID`, from which you can issue a
              manual `kill` command.

            """),
        Command(name: "status", allowableNumberOfArguments: [0], help: """
            horizon daemon status
              'horizon daemon status' prints the status of the daemon.
              The background daemon remains running so that contacts can access your
              shared files.

                > horizon daemon start
                > horizon daemon status
                Running (PID: 12345)

                > horizon daemon stop
                > horizon daemon status
                Stopped

            """),
        Command(name: "stop", allowableNumberOfArguments: [0], help: """
            horizon daemon stop
              'horizon daemon stop' stops the background daemon.
              The background daemon remains running so that contacts can access your
              shared files.

              The root directory for the daemon is located at `~/.horizon/<identity>`.
              If no particular identity was provided to horizon with the `--identity`
              flag, then the root for the daemon will be `~/.horizon/default`.

              If the daemon hangs for some reason, the PID can be found in written
              to a file at `~/.horizon/<identity>/PID`, from which you can issue a
              manual `kill` command.

            """),
        Command(name: "ls", allowableNumberOfArguments: [0], help: """
            horizon daemon ls
              'horizon daemon ls' lists the status of the daemon for each
              identity. This is extremely useful to quickly check if any unwanted
              horizon instances are running, or to potentially clean up after an
              unclean shutdown.

                > horizon daemon ls
                'default': Running (PID: 12345)
                'work': Running (PID: 67890)
                'test': Stopped
                'old-test': Error (PID: 6666 not running but PID file remains at ~/.horizon/old-test/PID)

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
    }

    // MARK: - Private Functions

    private func startDaemon() {

        if !FileManager.default.fileExists(atPath: config.path.path) {
            try! FileManager.default.createDirectory(at: config.path.deletingLastPathComponent(),
                                                     withIntermediateDirectories: true,
                                                     attributes: nil)

            let initialize = ipfsCommand(for: config)
            initialize.launchPath = "/usr/local/bin/ipfs"
            initialize.arguments = ["init"]
            initialize.launch()
            initialize.waitUntilExit()
            guard initialize.terminationStatus == 0 else {
                print("Failed to initialize IPFS instance")
                errorHandler()
            }

            let configAPI = ipfsCommand(for: config)
            configAPI.launchPath = "/usr/local/bin/ipfs"
            configAPI.arguments = ["config",
                                   "Addresses.API",
                                   "/ip4/127.0.0.1/tcp/\(config.apiPort)"]
            configAPI.launch()
            configAPI.waitUntilExit()
            guard configAPI.terminationStatus == 0 else {
                print("Failed to configure IPFS API address")
                errorHandler()
            }

            let configGateway = ipfsCommand(for: config)
            configGateway.launchPath = "/usr/local/bin/ipfs"
            configGateway.arguments = ["config",
                                       "Addresses.Gateway",
                                       "/ip4/127.0.0.1/tcp/\(config.gatewayPort)"]
            configGateway.launch()
            configGateway.waitUntilExit()
            guard configGateway.terminationStatus == 0 else {
                print("Failed to configure IPFS gateway address")
                errorHandler()
            }

            let configSwarm = ipfsCommand(for: config)
            configSwarm.launchPath = "/usr/local/bin/ipfs"
            configSwarm.arguments = ["config",
                                     "--json",
                                     "Addresses.Swarm",
                                     "[\"/ip4/0.0.0.0/tcp/\(config.swarmPort)\", \"/ip6/::/tcp/\(config.swarmPort)\"]"]
            configSwarm.launch()
            configSwarm.waitUntilExit()
            guard configSwarm.terminationStatus == 0 else {
                print("Failed to configure IPFS swarm addresses")
                errorHandler()
            }
        }

        let daemonProcess = ipfsCommand(for: config)
        daemonProcess.launchPath = "/usr/local/bin/ipfs"
        daemonProcess.arguments = ["daemon"]
        daemonProcess.launch()

        if let pidData = daemonProcess.processIdentifier.description.data(using: .utf8, allowLossyConversion: false) {
            try! pidData.write(to: config.daemonPIDPath)
        }

        completionHandler()
    }

    private func printDaemonStatus() {
        printStatus(for: config, withIdentityPrefix: false)
        completionHandler()
    }

    private func listDaemons() {
        let maybeIdentites = try? FileManager.default.contentsOfDirectory(at: config.horizonDirectory,
                                                                          includingPropertiesForKeys: [.isDirectoryKey],
                                                                          options: .skipsSubdirectoryDescendants)

        guard let identities = maybeIdentites else {
            print("Identity 'default': Stopped")
            errorHandler()
        }

        for identity in identities {
            let config = Configuration(identity: identity.lastPathComponent)
            printStatus(for: config, withIdentityPrefix: true)
        }

        completionHandler()
    }

    private func stopDaemon() {
        if let daemonPID = pid(at: config.daemonPIDPath) {
            kill(daemonPID, SIGKILL)
            try! FileManager.default.removeItem(at: config.daemonPIDPath)
            completionHandler()
        } else {
            print("Daemon not running")
            completionHandler()
        }

    }

    private func pid(at path: URL) -> Int32? {
        if let pidString = try? String(contentsOf: path), let pid = Int32(pidString) {
            return pid
        } else {
            return nil
        }
    }

    private func ipfsCommand(for config: ConfigurationProvider) -> Process {
        var environment = ProcessInfo().environment
        environment["IPFS_PATH"] = config.path.path

        let task = Process()
        task.standardError = nil
        task.standardOutput = nil
        task.standardInput = nil
        task.environment = environment
        return task
    }

    private func printStatus(for config: ConfigurationProvider, withIdentityPrefix: Bool = false) {
        let identityPrefix = withIdentityPrefix ? "Identity '\(config.identity)': " : ""

        if let daemonPID = pid(at: config.daemonPIDPath) {
            // Sending a signal of 0 to a process tests for existence
            let isDaemonRunning = (kill(daemonPID, 0) == 0)


            if !isDaemonRunning {
                print("\(identityPrefix)Error (PID: \(daemonPID.description) not running but PID file " +
                      "remains at \(config.daemonPIDPath.path))")
            } else {
                print("\(identityPrefix)Running (PID: \(daemonPID.description))")
            }
        } else {
            print("\(identityPrefix)Stopped")
        }
    }

}

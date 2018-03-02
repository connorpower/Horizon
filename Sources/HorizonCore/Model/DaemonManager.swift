//
//  DaemonManager.swift
//  HorizonCore
//
//  Created by Connor Power on 17.02.18.
//  Copyright © 2018 Connor Power. All rights reserved.
//

import Foundation

/**
 The `DaemonManager` groups all functionality related to controlling
 the IPFS daemon(s).
 */
public struct DaemonManager {

    // MARK: - Data Types

    public enum DaemonStatus {
        case running(Int32)
        case stopped
        case pidFilePresentButDaemonNotRunning(Int32)
    }

    // MARK: - Properties

    let ipfsPath = "/usr/local/bin/ipfs"

    // MARK: - Initializer

    public init() {}

    // MARK: - Public Functions

    /**
     A simple predicate which indicates whether IPFS can be found
     on the current system.
     */
    public var isIPFSPresent: Bool {
        return FileManager.default.isExecutableFile(atPath: ipfsPath)
    }

    /**
     Start the daemon relavant for the given configuration. Each daemon
     pertains to one "personality". By convention, if the user does
     not specify a personality then the "default" personality is used.

     The daemon's network ports will be altered to match those specified
     in the config file, and the PID will be written to the path specified
     in the config file once the deamon is running.

     - parameter configuration: The configuration for the daemon which
     should be started.
     - throws: Throws a `HorizonError.daemonOperationFailed` error if
     an operation failed.
     */
    public func startDaemon(for configuration: ConfigurationProvider) throws {
        if !FileManager.default.fileExists(atPath: configuration.path.path) {
            try? FileManager.default.createDirectory(at: configuration.path.deletingLastPathComponent(),
                                                     withIntermediateDirectories: true,
                                                     attributes: nil)
            try initializeNewIPFSNode(for: configuration)
            try configureIPFSNode(for: configuration)
        }

        let daemonProcess = ipfsCommand(for: configuration)
        daemonProcess.launchPath = ipfsPath
        daemonProcess.arguments = ["daemon"]
        daemonProcess.launch()

        if let pidData = daemonProcess.processIdentifier.description.data(using: .utf8, allowLossyConversion: false) {
            try? pidData.write(to: configuration.daemonPIDPath)
        }
    }

    /**
     Stops the daemon referred to by the configuration file.
     This function attempts to be as clean as possible – hence the
     PID file will be removed whether or not the daemon was
     running.

     - parameter configuration: The configuration for the daemon which
     should be stopped.
     - returns: Returns a boolean indicating whether start or stop
     was successful. If `false` is returned, then no PID file could
     be found for the daemon and hence it should be presumed that
     the daemon was not running.
     */
    public func stopDaemon(for configuration: ConfigurationProvider) -> Bool {
        if let daemonPID = pid(at: configuration.daemonPIDPath) {
            kill(daemonPID, SIGINT)
            try? FileManager.default.removeItem(at: configuration.daemonPIDPath)
            return true
        } else {
            return false
        }

    }

    /**
     Returns the status of the daemon referred to by the configuration.

     - parameter configuration: The configuration for the daemon whose
     status should be determined.
     - returns: Returns a `DaemonStatus` enum.
     */
    public func status(for configuration: ConfigurationProvider) -> DaemonStatus {
        if let daemonPID = pid(at: configuration.daemonPIDPath) {
            // Sending a signal of 0 to a process tests for existence
            let isDaemonRunning = (kill(daemonPID, 0) == 0)

            if !isDaemonRunning {
                return .pidFilePresentButDaemonNotRunning(daemonPID)
            } else {
                return .running(daemonPID)
            }
        } else {
            return .stopped
        }
    }

    // MARK: - private Functions

    private func initializeNewIPFSNode(for configuration: ConfigurationProvider) throws {
        let initialize = ipfsCommand(for: configuration)
        initialize.launchPath = ipfsPath
        initialize.arguments = ["init"]
        initialize.launch()
        initialize.waitUntilExit()
        guard initialize.terminationStatus == 0 else {
            throw HorizonError.daemonOperationFailed(reason: .ipfsInitFailed)
        }
    }

    private func configureIPFSNode(for configuration: ConfigurationProvider) throws {
        let configAPI = ipfsCommand(for: configuration)
        configAPI.launchPath = ipfsPath
        configAPI.arguments = ["config",
                               "Addresses.API",
                               "/ip4/127.0.0.1/tcp/\(configuration.apiPort)"]
        configAPI.launch()
        configAPI.waitUntilExit()
        guard configAPI.terminationStatus == 0 else {
            throw HorizonError.daemonOperationFailed(reason: .failedToAlterConfigFile)
        }

        let configGateway = ipfsCommand(for: configuration)
        configGateway.launchPath = ipfsPath
        configGateway.arguments = ["config",
                                   "Addresses.Gateway",
                                   "/ip4/127.0.0.1/tcp/\(configuration.gatewayPort)"]
        configGateway.launch()
        configGateway.waitUntilExit()
        guard configGateway.terminationStatus == 0 else {
            throw HorizonError.daemonOperationFailed(reason: .failedToAlterConfigFile)
        }

        let ipv4SwarmAddr = "\"/ip4/0.0.0.0/tcp/\(configuration.swarmPort)\""
        let ipv6SwarmAddr = "\"/ip6/::/tcp/\(configuration.swarmPort)\""
        let configSwarm = ipfsCommand(for: configuration)
        configSwarm.launchPath = ipfsPath
        configSwarm.arguments = ["config",
                                 "--json",
                                 "Addresses.Swarm",
                                 "[\(ipv4SwarmAddr), \(ipv6SwarmAddr)]"]
        configSwarm.launch()
        configSwarm.waitUntilExit()
        guard configSwarm.terminationStatus == 0 else {
            throw HorizonError.daemonOperationFailed(reason: .failedToAlterConfigFile)
        }
    }

    private func ipfsCommand(for configuration: ConfigurationProvider) -> Process {
        var environment = ProcessInfo().environment
        environment["IPFS_PATH"] = configuration.path.path

        let task = Process()
        task.standardError = nil
        task.standardOutput = nil
        task.standardInput = nil
        task.environment = environment
        return task
    }

    private func pid(at path: URL) -> Int32? {
        if let pidString = try? String(contentsOf: path), let pid = Int32(pidString) {
            return pid
        } else {
            return nil
        }
    }

}

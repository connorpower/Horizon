//
//  IPFSConfiguration.swift
//  HorizonCore
//
//  Created by Connor Power on 16.02.18.
//

import Foundation

public struct IPFSConfiguration {

    // MARK: - Properties

    public let instanceNumber: Int
    public let path: URL
    public let daemonPIDPath: URL
    public let apiPort: Int
    public let gatewayPort: Int
    public let swarmPort: Int
    public let apiBasePath: String

    // MARK: - Initialization

    public init(instanceNumber: Int) {
        self.instanceNumber = instanceNumber
        self.path = URL(fileURLWithPath: ("~/.horizon/instance\(instanceNumber)" as NSString).expandingTildeInPath)
        self.daemonPIDPath = self.path.appendingPathComponent("PID")
        self.apiPort = 5001 + instanceNumber
        self.gatewayPort = 8080 + instanceNumber
        self.swarmPort = 4001 + instanceNumber
        self.apiBasePath = "http://127.0.0.1:\(5001 + instanceNumber)/api/v0"
    }

}

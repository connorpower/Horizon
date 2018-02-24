//
//  DaemonManager+Extension.swift
//  horizon
//
//  Created by Connor Power on 24.02.18.
//

import Foundation
import HorizonCore

extension DaemonManager {

    func startDaemonIfNecessary(_ configuration: ConfigurationProvider) -> Bool {
        switch DaemonManager().status(for: configuration) {
        case .pidFilePresentButDaemonNotRunning, .stopped:
            print("Horizon daemon not running. Auto-starting...")
            do {
                try DaemonManager().startDaemon(for: configuration)
            } catch {
                print("Failed to start daemon.")
                exit(EXIT_FAILURE)
            }
            print("Started 🤖")
            return true
        default:
            return false
        }
    }

    func stopDaemonIfNecessary(_ configuration: ConfigurationProvider) {
        switch DaemonManager().status(for: configuration) {
        case .running:
            print("Stopping daemon...")
            if DaemonManager().stopDaemon(for: configuration) {
                print("Stopped 🤖")
            } else {
                print("Failed to stop daemon after auto-starting.")
                exit(EXIT_FAILURE)
            }
        default:
            break
        }
    }

}

//
//  Loggers.swift
//  Horizon
//
//  Created by Connor Power on 07.01.18.
//  Copyright © 2018 Semantical GmbH & Co. KG. All rights reserved.
//

import Foundation
import os.log

/**
 A pre-defined set of loggers for the application, categorized
 by major application domains for easy filtering in the Console
 App as per Apple's recommendations.
 */
struct Loggers {

    /**
     A logger to be used for network related log messages.
     */
    static let network = OSLog(subsystem: "com.semantical.Horizon", category: "network")

}

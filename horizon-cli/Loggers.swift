//
//  Loggers.swift
//  horizon-cli
//
//  Created by Connor Power on 02.02.18.
//  Copyright © 2018 Semantical GmbH & Co. KG. All rights reserved.
//

import Foundation
import HorizonCore
import os.log

/**
 A pre-defined set of loggers for the application, categorized
 by major application domains for easy filtering in the Console
 App as per Apple's recommendations.
 */
struct Loggers: LogProvider {

    /**
     A logger to be used for network related log messages.
     */
    let network = OSLog(subsystem: "com.semantical.horizon-cli", category: "network")

}

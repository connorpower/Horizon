//
//  LogProvider.swift
//  HorizonCore
//
//  Created by Connor Power on 22.01.18.
//  Copyright © 2018 Connor Power. All rights reserved.
//

import Foundation
import os.log

/**
 An interface allowing access to a pre-defined set of loggers provided
 by the host application but used internally in the core framework.

 The loggers are categorized by major application domains for easy
 filtering in the Console App as per Apple's recommendations.
 */
public protocol LogProvider {

    /**
     A logger to be used for network related log messages.
     */
    var network: OSLog { get }

}

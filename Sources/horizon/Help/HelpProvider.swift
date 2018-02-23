//
//  HelpProvider.swift
//  horizon
//
//  Created by Connor Power on 23.02.18.
//

import Foundation

protocol HelpProvider {

    static var longHelp: String { get }
    static var shortHelp: String { get }

}

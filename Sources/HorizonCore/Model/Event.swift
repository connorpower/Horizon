//
//  Event.swift
//  HorizonCore
//
//  Created by Connor Power on 22.01.18.
//  Copyright © 2018 Semantical GmbH & Co. KG. All rights reserved.
//

import Foundation

public enum Event {
    case errorEvent(HorizonError)

    case syncDidStart
    case syncDidEnd
    case propertiesDidChange(Contact)

    case resolvingReceiveListDidStart(Contact)
    case addingFileToIPFSDidStart(URL)
    case keygenDidStart(String)
    case removeKeyDidStart(String)
    case renameKeyDidStart(String, String)
    case listKeysDidStart
    case addingProvidedFileListToIPFSDidStart(Contact)
    case publishingFileListToIPNSDidStart(Contact)
    case downloadingReceiveListDidStart(Contact)
    case processingReceiveListDidStart(Contact)
}

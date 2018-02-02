//
//  Event.swift
//  HorizonCore
//
//  Created by Connor Power on 22.01.18.
//  Copyright © 2018 Semantical GmbH & Co. KG. All rights reserved.
//

import Foundation

public enum Event {

    case syncDidStart
    case syncDidFail(ErrorEvent)
    case syncDidEnd
    case propertiesDidChange(Contact)

    case resolvingReceiveListDidStart(Contact)
    case addingFileToIPFSDidStart(File)
    case keygenDidStart(String)
    case keygenDidFail(ErrorEvent)
    case listKeysDidStart
    case listKeysDidFail(ErrorEvent)
    case addingProvidedFileListToIPFSDidStart(Contact)
    case publishingFileListToIPNSDidStart(Contact)
    case downloadingReceiveListDidStart(Contact)
    case processingReceiveListDidStart(Contact)

}

public enum ErrorEvent: Error {

    case keypairAlreadyExists(String)
    case networkError(Error?)
    case invalidJSONAtPath(String)
    case JSONEncodingErrorForContact(Contact)

}

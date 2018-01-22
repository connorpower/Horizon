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
    case addingProvidedFileListToIPFSDidStart(Contact)
    case publishingFileListToIPNSDidStart(Contact)
    case downloadingReceiveListDidStart(Contact)
    case processingReceiveListDidStart(Contact)

}

public enum ErrorEvent: Error {

    case networkError(Error?)
    case invalidJSONAtPath(String)
    case JSONEncodingErrorForContact(Contact)

}

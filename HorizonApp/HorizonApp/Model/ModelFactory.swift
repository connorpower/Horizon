//
//  ModelFactory.swift
//  Horizon
//
//  Created by Connor Power on 22.01.18.
//  Copyright © 2018 Semantical GmbH & Co. KG. All rights reserved.
//

import Foundation
import HorizonCore

struct ModelFactory {

    func model() -> Model {
        let api = IPFSWebserviceAPI(logProvider: Loggers())

        let model = Model(api: api, eventCallback: { self.handleEvent($0) })

        return model
    }

    private func handleEvent(_ event: Event) {
        switch event {
        case .syncDidStart:
            Notifications.broadcastSyncStart()
        case .syncDidFail(let errorEvent):
            handleErrorEvent(errorEvent)
        case .syncDidEnd:
            Notifications.broadcastSyncEnd()
        case .propertiesDidChange:
            Notifications.broadcastNewData()
        case .resolvingReceiveListDidStart(let contact):
            Notifications.broadcastStatusMessage(
                "Interplanetary Naming System: Resolving location of \(contact.displayName)...")
        case .addingFileToIPFSDidStart(let file):
            Notifications.broadcastStatusMessage(
                "Interplanetary File System: Adding \(file.name)...")
        case .addingProvidedFileListToIPFSDidStart(let contact):
            Notifications.broadcastStatusMessage(
                "Interplanetary File System: Uploading file list for \(contact.displayName)...")
        case .publishingFileListToIPNSDidStart(let contact):
            Notifications.broadcastStatusMessage(
                "Interplanetary Naming System: Publishing file list for \(contact.displayName)...")
        case .downloadingReceiveListDidStart(let contact):
            Notifications.broadcastStatusMessage(
                "Interplanetary File System: Downloading file list from \(contact.displayName)...")
        case .processingReceiveListDidStart(let contact):
            Notifications.broadcastStatusMessage(
                "Interplanetary File System: Processing file list from \(contact.displayName)...")
        case .keygenDidStart(_):
            break
        case .keygenDidFail(_):
            break
        case .listKeysDidStart:
            break
        case .listKeysDidFail(_):
            break
        }
    }

    private func handleErrorEvent(_ errorEvent: ErrorEvent) {
        switch errorEvent {
        case .networkError(let error):
            Notifications.broadcastStatusMessage("IPFS or network error encountered...")
            print(error as Any)
        case .invalidJSONAtPath(let path):
            Notifications.broadcastStatusMessage("Failed to decode JSON at \(path)...")
        case .JSONEncodingErrorForContact(let contact):
            Notifications.broadcastStatusMessage("Internal encoding file list for \(contact.displayName)...")
        case .keypairAlreadyExists(_):
            break
        }
    }

}

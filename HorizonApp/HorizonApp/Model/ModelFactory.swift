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
        let horizonDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let config = Configuration(horizonDirectory: horizonDirectory, identity: "default")

        let api = IPFSWebserviceAPI(logProvider: Loggers())
        let store = UserDefaultsStore(config: config)

        let model = Model(api: api, config: config, persistentStore: store, eventCallback: { self.handleEvent($0) })

        return model
    }

    private func handleEvent(_ event: Event) {
        switch event {
        case .errorEvent(let errorEvent):
            handleErrorEvent(errorEvent)
        case .syncDidStart:
            Notifications.broadcastSyncStart()
        case .syncDidEnd:
            Notifications.broadcastSyncEnd()
        case .propertiesDidChange:
            Notifications.broadcastNewData()
        case .resolvingReceiveListDidStart(let contact):
            Notifications.broadcastStatusMessage(
                "Interplanetary Naming System: Resolving location of \(contact.displayName)...")
        case .addingFileToIPFSDidStart(let url):
            Notifications.broadcastStatusMessage(
                "Interplanetary File System: Adding \(url.path)...")
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
        case .keygenDidStart:
            break
        case .listKeysDidStart:
            break
        case .removeKeyDidStart:
            break
        case .renameKeyDidStart:
            break
        }
    }

    private func handleErrorEvent(_ error: HorizonError) {}

}

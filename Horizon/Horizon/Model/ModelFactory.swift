//
//  ModelFactory.swift
//  Horizon
//
//  Created by Connor Power on 22.01.18.
//  Copyright © 2018 Connor Power. All rights reserved.
//

import Foundation
import HorizonCore

struct ModelFactory {

    func model() -> Model {
        let horizonDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let configuration = Configuration(horizonDirectory: horizonDirectory, identity: "default")

        let api = IPFSWebserviceAPI(logProvider: Loggers())
        let store = UserDefaultsStore(configuration: configuration)

        let model = Model(api: api,
                          configuration: configuration,
                          persistentStore: store,
                          eventCallback: { self.handleEvent($0) })

        return model
    }

    private func handleEvent(_ event: Event) {}

    private func handleErrorEvent(_ error: HorizonError) {}

}

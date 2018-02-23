//
//  GetDataTask.swift
//  HorizonCore
//
//  Created by Connor Power on 23.02.18.
//

import Foundation
import PromiseKit
import IPFSWebService

struct GetDataTask: ModelTask {

    // MARK: - Properties

    private let model: Model

    // MARK: - Initializer

    init(model: Model) {
        self.model = model
    }

    // MARK: - Functions

    func data(for file: File) -> Promise<Data> {
        guard let hash = file.hash else {
            return Promise<Data>(error: HorizonError.fileOperationFailed(reason: .fileHashNotSet))
        }

        return firstly {
            return self.model.api.cat(arg: hash)
        }.catch { error in
            let horizonError: HorizonError
            if let castError = error as? HorizonError {
                horizonError = castError
            } else {
                horizonError = HorizonError.fileOperationFailed(reason: .unknown(error))
            }
            self.model.eventCallback?(.errorEvent(horizonError))
        }
    }

}

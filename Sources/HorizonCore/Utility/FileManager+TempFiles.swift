//
//  FileManager+TempFiles.swift
//  HorizonCore
//
//  Created by Connor Power on 10.02.18.
//

import Foundation

extension FileManager {

    func encodeAsJSONInTemporaryFile<T>(_ object: T) -> URL? where T : Encodable {
        guard let data = try? JSONEncoder().encode(object) else {
            return nil
        }

        let tempDir: URL
        do {
            tempDir = try FileManager.default.url(for: .itemReplacementDirectory, in: .userDomainMask,
                                                  appropriateFor: URL(fileURLWithPath: "/"), create: true)
        } catch {
            return nil
        }

        let temporaryFile = tempDir.appendingPathComponent(UUID().uuidString + ".json")
        do {
            try data.write(to: temporaryFile)
        } catch {
            return nil
        }

        return temporaryFile
    }
    
}

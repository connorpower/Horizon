//
//  FileManager+utilities.swift
//  HorizonCore
//
//  Created by Connor Power on 10.02.18.
//

import Foundation

public extension FileManager {

    /**
     Encodes a given `Encodable` object to a temporary file as JSON.

     - parameter object: An object conforming to `Encodable`.
     - returns: A `URL` if the object was sucessfully encoded and written
     to a file, or `nil` otherwise.
     */
    public func encodeAsJSONInTemporaryFile<T>(_ object: T) -> URL? where T : Encodable {
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

    /**
     Returns a finder style safe path, either matching the proposed
     path or with a suffix added so as not to overwrite the existing
     file at that location.

     For instance, if `file.txt` already exists,
     `finderStyleSafePath(for:atProposedPath:)` would return `file (2).txt`.
     If `file (2).txt` also happened to exist, the function would return
     `file (3).txt`, and so on.

     - parameter file: The file object which should be moved or copied to
     the `path`.
     - parameter path: The propose path which may or may not be modified
     in order to ensure no conflict with an existing file at this path.
     - returns: Returns a safe path in the form of a file `URL`.
     */
    public func finderStyleSafePath(for file: File, atProposedPath path: URL) -> URL {
        let targetLocation = (path.path as NSString).expandingTildeInPath
        let location: URL

        var isDir = ObjCBool(false)
        if !FileManager.default.fileExists(atPath: targetLocation, isDirectory: &isDir) {
            location = URL(fileURLWithPath: targetLocation)
        } else {
            var maybeLocation: URL?
            var counter = 1

            repeat {
                if isDir.boolValue {
                    let filename = file.name + (counter == 1 ? "" : " (\(counter.description))")
                    maybeLocation = URL(fileURLWithPath: targetLocation).appendingPathComponent(filename)
                } else {
                    let newSuffix = counter == 1 ? "" : " (\(counter.description))"
                    let baseBath = (targetLocation as NSString).deletingPathExtension
                    let pathExtension = (targetLocation as NSString).pathExtension
                    let newPath = baseBath + newSuffix + (pathExtension.isEmpty ? "" : ".") + pathExtension
                    maybeLocation = URL(fileURLWithPath: newPath)
                }
                counter += 1
            } while FileManager.default.fileExists(atPath: maybeLocation!.path)

            location = maybeLocation!
        }

        return location
    }
    
}

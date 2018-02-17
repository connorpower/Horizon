//
//  HorizonError.swift
//  HorizonCore
//
//  Created by Connor Power on 03.02.18.
//

import Foundation

public enum HorizonError: Error {

    /**
     The underlying reason a contact-related command failed.

     - unknown: An unknown reason caused the command to fail.
     - contactAlreadyExists: A contact of the same name already
     exists and would have been overwritten by the operation.
     - contactDoesNotExist: No contact of the specified name
     could be found.
     */
    public enum ContactOperationFailureReason {
        case unknown(Error)
        case contactAlreadyExists
        case contactDoesNotExist
    }

    /**
     The underlying reason the attempt to share a file or files failed.

     - unknown: An unknown reason caused the command to fail.
     - sendAddressNotSet: The contact does not have a send address set.
     - fileDoesNotExist: The file either does not exist or is not readable.
     - fileNotShared: The file was never shared, and the requested
     operation therefore did not make sense (unsharing, etc.)
     - failedToEncodeFileListToTemporaryFile: Something went wrong
     either with encoding the list of shared files to JSON, or with
     writing the encoded result to a temp file for uploading into IPFS.
     */
    public enum ShareOperationFailureReason {
        case unknown(Error)
        case sendAddressNotSet
        case fileDoesNotExist(String)
        case fileNotShared
        case failedToEncodeFileListToTemporaryFile
    }

    /**
     The underlying reason the attempt to retreive a file or files failed.

     - unknown: An unknown reason caused the command to fail.
     - fileHashNotSet: The requested file was missing a hash address.
     - fileNotFound: The file could not be found in IPFS. Most likely
     the contact who shared the file is not online and it is not present
     in any IPFS caches.
     */
    public enum FileOperationFailureReason {
        case unknown(Error)
        case fileHashNotSet
    }

    /**
     The underlying reason the sync command failed.
     - unknown: An unknown reason caused the command to fail.
     - invalidJSONForIPFSObject: The IPFS object pointed to by the
     associated data has did not contain valid JSON.
     */
    public enum SyncOperationFailureReason {
        case unknown(Error)
        case invalidJSONForIPFSObject(String)
    }

    case contactOperationFailed(reason: ContactOperationFailureReason)
    case shareOperationFailed(reason: ShareOperationFailureReason)
    case fileOperationFailed(reason: FileOperationFailureReason)
    case syncOperationFailed(reason: SyncOperationFailureReason)

}

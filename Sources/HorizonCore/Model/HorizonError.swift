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
     The underlying reason the sync command failed.
     - unknown: An unknown reason caused the command to fail.
     */
    public enum SyncFailureReason {
        case unknown(Error)
    }

    /**
     The underlying reason the add file command failed.
     - unknown: An unknown reason caused the command to fail.
     */
    public enum AddFileFailureReason {
        case unknown(Error)
    }

    /**
     The underlying reason the attempt to retrieve a contact's filelist failed.
     - unknown: An unknown reason caused the command to fail.
     */
    public enum RetrieveFileListFailureReason {
        case unknown(Error)
        case invalidJSONAtPath(String)
    }

    /**
     The underlying reason the attempt to send a filelist failed.
     - unknown: An unknown reason caused the command to fail.
     */
    public enum SendFileListFailureReason {
        case unknown(Error)
        case failedToWriteTemporaryFile(URL)
        case failedToCreateTemporaryDirectory
        case failedToEncodeFileList
    }

    case contactOperationFailed(reason: ContactOperationFailureReason)
    case syncFailed(reason: SyncFailureReason)
    case addFileFailed(reason: AddFileFailureReason)
    case retrieveFileListFailed(reason: RetrieveFileListFailureReason)
    case sendFileListFailed(reason: SendFileListFailureReason)
}

//
//  HorizonError.swift
//  HorizonCore
//
//  Created by Connor Power on 03.02.18.
//

import Foundation

public enum HorizonError: Error {

    /**
     The underlying reason the add contact command failed.
     - unknown: An unknown reason caused the command to fail.
     */
    public enum AddContactFailureReason {
        case unknown(Error)
        case contactAlreadyExists
    }

    /**
     The underlying reason the remove contact command failed.
     - unknown: An unknown reason caused the command to fail.
     */
    public enum RemoveContactFailureReason {
        case unknown(Error)
        case contactDoesNotExist
    }

    /**
     The underlying reason the rename contact command failed.
     - unknown: An unknown reason caused the command to fail.
     */
    public enum RenameContactFailureReason {
        case unknown(Error)
        case contactDoesNotExist
        case newNameAlreadyExists
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

    case addContactFailed(reason: AddContactFailureReason)
    case removeContactFailed(reason: RemoveContactFailureReason)
    case renameContactFailed(reason: RenameContactFailureReason)
    case syncFailed(reason: SyncFailureReason)
    case addFileFailed(reason: AddFileFailureReason)
    case retrieveFileListFailed(reason: RetrieveFileListFailureReason)
    case sendFileListFailed(reason: SendFileListFailureReason)
}

//
//  Model.swift
//  HorizonCore
//
//  Created by Jürgen on 02.11.17.
//  Copyright © 2017 Semantical GmbH & Co. KG. All rights reserved.
//

import Foundation
import PromiseKit
import IPFSWebService

public class Model {

    // MARK: - Properties

    internal let persistentStore: PersistentStore

    internal let api: IPFSAPI

    internal let configuration: ConfigurationProvider

    internal let eventCallback: ((Event) -> Void)?

    // MARK: - Initialization

    public init(api: IPFSAPI,
                configuration: ConfigurationProvider,
                persistentStore: PersistentStore,
                eventCallback: ((Event) -> Void)?) {
        self.api = api
        self.configuration = configuration
        self.persistentStore = persistentStore
        self.eventCallback = eventCallback
    }

}

// MARK: - Contact Functionality

/**
 An extension which groups all contact related model functionality into
 one place.
 */
public extension Model {

    /**
     Returns an unordered list of all contacts.
     */
    public var contacts: [Contact] {
        return persistentStore.contacts
    }

    /**
     Searches for a contact based on display name.

     - parameter name: The display name of the contact to search for.
     - returns: Returns a contact matching the given display name or
     nil if no match could be found.
     */
    public func contact(named name: String) -> Contact? {
        return contacts.filter({ $0.displayName == name }).first
    }

    /**
     Updates the receive address of a given contact.

     - paramter contact: The contact to update.
     - parameter receiveAddress: The new receive address to set.
     */
    public func updateReceiveAddress(for contact: Contact, to receiveAddress: String) {
        persistentStore.createOrUpdateContact(contact.updatingReceiveAddress(receiveAddress))
    }

    /**
     Adds a new contact. A send address for the contact will be automatically
     generated.

     **Note:** IPFS must be online.

     - paramter name: The display name of the contact to create.
     - returns: Returns either a promise which, when fulfilled, will contain
     the newly created contact or require handling of an
     `HorizonError.contactOperationFailed` error.
     */
    public func addContact(name: String) -> Promise<Contact> {
        return AddContactTask(model: self).addContact(name: name)
    }

    /**
     Removes a contact. This function is tolerant - an orphaned IPFS key
     for a nonexistent contact will be removed and reported as success.

     **Note:** IPFS must be online.

     - paramter name: The display name of the contact to remove.
     - returns: Returns either a promise which, when fulfilled, will indicate
     successful removal or require handling of an `HorizonError.contactOperationFailed`
     error.
     */
    public func removeContact(name: String) -> Promise<Void> {
        return RemoveContactTask(model: self).removeContact(name: name)
    }

    /**
     Renames a contact. This function will refuse to rename a contact
     if a contact aleady exists for the proposed new name.

     **Note:** IPFS must be online.

     - paramter name: The display name of the contact to rename.
     - parameter newName: The new display name for the contact.
     - returns: Returns either a promise which, when fulfilled, will contain
     the new `Contact` object or require handling of an
     `HorizonError.contactOperationFailed` error.
     */
    public func renameContact(_ name: String, to newName: String) -> Promise<Contact> {
        return RenameContactTask(model: self).renameContact(name, to: newName)
    }

}

// MARK: - File Sharing Functionality

/**
 An extension which groups all related file sharing functionality
 into one place.
 */
public extension Model {

    /**
     Shares one or more files with a contact.

     The list if files must first be uploaded individually to IPFS. When all
     files are uploaded, the contact's shareList with be updated and itself
     uploaded as a new file to IPFS (having been serialized to a temporary
     file), then finally the newly uploaded shareList will be published
     on the contact's sendAddress using IPFS.

     **Note:** IPFS must be online.

     - parameter files: An array of URLs to files on the local system which
     will be shared with the contact.
     - parameter contact: The contact with which to share the files.
     - returns: Returns either a promise which, when fulfilled, will contain either:
       1. a new `Contact` object complete with updated share lists, or;
       2. require handling of an `HorizonError.shareOperationFailed` error.
     */
    public func shareFiles(_ files: [URL], with contact: Contact) -> Promise<Contact> {
        return ShareFileTask(model: self).shareFiles(files, with: contact)
    }

    /**
     Remove one or more files from the list of files shared with a contact.

     1. The contact's share list with be updated to remove the given files
     2. The updated share list will be uploaded as a new file to IPFS
     3. The updated share list will be published to the contact's send address
         using IPNS

     **Note:** IPFS must be online.

     - parameter files: An array of `Files` to stop sharing with the contact.
     - parameter contact: The contact with which to stop sharing the files.
     - returns: Returns either a promise which, when fulfilled, will contain either:
       1. a new `Contact` object complete with updated share lists, or;
       2. require handling of an `HorizonError.shareOperationFailed` error.
     */
    public func unshareFiles(_ files: [File], with contact: Contact) -> Promise<Contact> {
        return UnshareFileTask(model: self).unshareFiles(files, with: contact)
    }

    /**
     Returns an unordered list of received files and their associated contacts.
     */
    public var receivedFiles: [(File, Contact)] {
        return persistentStore.contacts.flatMap { contact in
            return contact.receiveList.files.map { ($0, contact) }
        }
    }

    /**
     Returns an unordered list of sent files and their associated contacts.
     */
    public var sentFiles: [(File, Contact)] {
        return persistentStore.contacts.flatMap { contact in
            return contact.sendList.files.map { ($0, contact) }
        }
    }

    /**
     Searches for a file of a given name wither shared with or shared
     from a given contact.

     - parameter fileName: The name of the file, excluding any path
     information.
     - parameter contact: The contact which has sent the file or
     received the file from you.
     - returns: Returns a file if one was found, otherwise nil.
     */
    public func file(named fileName: String, sentOrReceivedFrom contact: Contact) -> File? {
        let matches = (contact.sendList.files + contact.receiveList.files).filter { file in
            return file.name == fileName
        }

        return matches.first
    }

    /**
     Searches for a file based on it's hash. The file could be either
     one shared with a contact, or a file received from a contact. If
     the hash matches multiple files, the first match will be returned -
     in this case, there is no guarantee made as to which.

     - parameter hash: The hash of a file to search for.
     - returns: Returns a file if one was found, otherwise nil.
     */
    public func file(matching hash: String) -> File? {
        let matches = (receivedFiles + sentFiles).filter { file, _ in
            return file.hash == hash
        }

        return matches.first?.0
    }

    public func data(for file: File) -> Promise<Data> {
        return GetDataTask(model: self).data(for: file)
    }

}

// MARK: - Sync

public extension Model {

    /**
     Sync the receive lists from each contact.

     1. Each contact's receive list will be resolved via their receive address IPNS
     2. Each contact's resolved receive list will be downloaded via IPFS
     3. Each contact's receive list will be updated and the contact will be re-saved

     **Note:** IPFS must be online.

     - returns: Returns either a promise which, when fulfilled, will contain either:
     1. a list of all `Contact` objects complete with updated receive lists, or;
     2. require handling of an `HorizonError.syncOperationFailed` error.
     */
    public func sync() -> Promise<[SyncState]> {
        return SyncTask(model: self).sync()
    }

}

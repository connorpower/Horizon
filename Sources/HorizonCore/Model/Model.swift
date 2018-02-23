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

    private let persistentStore: PersistentStore

    private let api: IPFSAPI

    private let config: ConfigurationProvider

    private let eventCallback: ((Event) -> Void)?

    // MARK: - Initialization

    public init(api: IPFSAPI,
                config: ConfigurationProvider,
                persistentStore: PersistentStore,
                eventCallback: ((Event) -> Void)?) {
        self.api = api
        self.config = config
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
        let keypairName = "\(config.persistentStoreKeys.keypairPrefix).\(name)"

        guard contact(named: name) == nil else {
            return Promise(error: HorizonError.contactOperationFailed(reason: .contactAlreadyExists))
        }

        return firstly {
            return self.api.listKeys()
        }.then { listKeysResponse  -> Promise<KeygenResponse> in
            if listKeysResponse.keys.map({ $0.name }).contains(keypairName) {
                throw HorizonError.contactOperationFailed(reason: .contactAlreadyExists)
            }

            self.eventCallback?(.keygenDidStart(keypairName))
            return self.api.keygen(keypairName: keypairName, type: .rsa, size: 2048)
        }.then { keygenResponse in
            let sendAddress = SendAddress(address: keygenResponse.id, keypairName: keygenResponse.name)
            let contact = Contact(identifier: UUID(), displayName: name,
                                  sendAddress: sendAddress, receiveAddress: nil)

            self.persistentStore.createOrUpdateContact(contact)
            self.eventCallback?(.propertiesDidChange(contact))
            return Promise(value: contact)
        }.catch { error in
            let horizonError: HorizonError = error is HorizonError
                ? error as! HorizonError : HorizonError.contactOperationFailed(reason: .unknown(error))
            self.eventCallback?(.errorEvent(horizonError))
        }
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
        // Dont rely entirely on the keypair name or the contact. The
        // contact was potentially deleted, leaving behind a dangling IPNS keypair or vice versa.
        let contact = self.contact(named: name)
        let keypairName = "\(config.persistentStoreKeys.keypairPrefix).\(name)"

        return firstly {
            return self.api.listKeys()
        }.then { listKeysResponse -> Promise<Void> in

            // Branch 1: the underlying IPFS key is missing, but we may have a model contact object.
            guard listKeysResponse.keys.map({ $0.name }).contains(keypairName) else {
                if let contact = contact {
                    self.persistentStore.removeContact(contact)
                    self.eventCallback?(.propertiesDidChange(contact))

                    return Promise(value: ())
                } else {
                    throw HorizonError.contactOperationFailed(reason: .contactDoesNotExist)
                }
            }

            // Branch 2: the underlying IPFS key present, and we may have a model contact object.
            self.eventCallback?(.removeKeyDidStart(name))
            return firstly {
                return self.api.removeKey(keypairName: keypairName)
            }.then { _ in
                if let contact = contact {
                    self.persistentStore.removeContact(contact)
                    self.eventCallback?(.propertiesDidChange(contact))
                }
                return Promise(value: ())
            }
        }.catch { error in
            let horizonError: HorizonError = error is HorizonError
                ? error as! HorizonError : HorizonError.contactOperationFailed(reason: .unknown(error))
            self.eventCallback?(.errorEvent(horizonError))
        }
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
        let keypairName = "\(config.persistentStoreKeys.keypairPrefix).\(name)"
        let newKeypairName = "\(config.persistentStoreKeys.keypairPrefix).\(newName)"

        guard let contact = self.contact(named: name) else {
            return Promise<Contact>(error: HorizonError.contactOperationFailed(reason: .contactDoesNotExist))
        }

        guard self.contact(named: newName) == nil else {
            return Promise<Contact>(error: HorizonError.contactOperationFailed(reason: .contactAlreadyExists))
        }

        return firstly {
            return self.api.listKeys()
        }.then { listKeysResponse -> Promise<RenameKeyResponse> in
            let currentNames = listKeysResponse.keys.map({ $0.name })
            if !currentNames.contains(keypairName) {
                throw HorizonError.contactOperationFailed(reason: .contactDoesNotExist)
            }
            if currentNames.contains(newKeypairName) {
                throw HorizonError.contactOperationFailed(reason: .contactAlreadyExists)
            }

            self.eventCallback?(.renameKeyDidStart(keypairName, newKeypairName))
            return self.api.renameKey(keypairName: keypairName, to: newKeypairName)
        }.then { renameKeyResponse in
            let sendAddress = SendAddress(address: renameKeyResponse.id, keypairName: renameKeyResponse.now)
            let updatedContact = contact.updatingDisplayName(newName).updatingSendAddress(sendAddress)

            self.persistentStore.createOrUpdateContact(updatedContact)
            self.eventCallback?(.propertiesDidChange(updatedContact))
            return Promise(value: updatedContact)
        }.catch { error in
            let horizonError: HorizonError = error is HorizonError
                ? error as! HorizonError : HorizonError.contactOperationFailed(reason: .unknown(error))
            self.eventCallback?(.errorEvent(horizonError))
        }
    }

}

// MARK: - File Sharing Functionality (Outbound)

/**
 An extension which groups all related outbound file sharing functionality
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
        guard let sendAddress = contact.sendAddress else {
            return Promise(error: HorizonError.shareOperationFailed(reason: .sendAddressNotSet))
        }

        // It is ill-advised to check for the presence of a file **before** peforming
        // an operation, but unfortunately the errors we receive from Alamofire are
        // relatively well buried and obtuse, so we peform the sanity checking here.
        // Parsing the AFErrors should probably be encapsulated in a helper extension
        // so we can react to a failure rather than check in advance – as apple suggests.
        for file in files {
            if !FileManager.default.isReadableFile(atPath: file.path) {
                return Promise(error: HorizonError.shareOperationFailed(reason: .fileDoesNotExist(file.path)))
            }
        }

        return firstly {
            when(fulfilled: files.map({ file -> Promise<AddResponse> in
                self.eventCallback?(.addingFileToIPFSDidStart(file))
                return self.api.add(file: file)
            }))
        }.then { addFileResponses -> Promise<(AddResponse, Contact)> in
            let newFiles = addFileResponses.map({ return File(name: $0.name, hash: $0.hash) })
            let updatedSendList = FileList(hash: nil, files: Array(Set(contact.sendList.files + newFiles)))
            let updatedContact = contact.updatingSendList(updatedSendList)
            self.persistentStore.createOrUpdateContact(updatedContact)

            guard let newSendListURL = FileManager.default.encodeAsJSONInTemporaryFile(updatedSendList.files) else {
                throw HorizonError.shareOperationFailed(reason: .failedToEncodeFileListToTemporaryFile)
            }

            self.eventCallback?(.addingProvidedFileListToIPFSDidStart(contact))

            // Keep passing the updated contact forward
            return self.api.add(file: newSendListURL).then { ($0, updatedContact) }
        }.then { addFileFesponse, contact -> Promise<(PublishResponse, Contact)> in
            self.eventCallback?(.publishingFileListToIPNSDidStart(contact))

            let sendListHash = addFileFesponse.hash
            let updatedSendList = contact.sendList.updatingHash(sendListHash)
            let updatedContact = contact.updatingSendList(updatedSendList)
            self.persistentStore.createOrUpdateContact(updatedContact)

            // Keep passing the updated contact forward
            return self.api.publish(arg: sendListHash, key: sendAddress.keypairName).then { ($0, updatedContact) }
        }.then { _, contact in
            return Promise(value: contact)
        }.catch { error in
            let horizonError: HorizonError = error is HorizonError
                ? error as! HorizonError : HorizonError.shareOperationFailed(reason: .unknown(error))
            self.eventCallback?(.errorEvent(horizonError))
        }
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
        guard let sendAddress = contact.sendAddress else {
            return Promise(error: HorizonError.shareOperationFailed(reason: .sendAddressNotSet))
        }

        guard contact.sendList.files.filter({ files.contains($0) }).first != nil else {
            return Promise(error: HorizonError.shareOperationFailed(reason: .fileNotShared))
        }

        return firstly { () -> Promise<(AddResponse, Contact)> in
            let filteredFiles = contact.sendList.files.filter() { !files.contains($0) }
            let updatedSendList = FileList(hash: nil, files: filteredFiles)
            let updatedContact = contact.updatingSendList(updatedSendList)

            guard let newSendListURL = FileManager.default.encodeAsJSONInTemporaryFile(updatedSendList.files) else {
                throw HorizonError.shareOperationFailed(reason: .failedToEncodeFileListToTemporaryFile)
            }

            self.eventCallback?(.addingProvidedFileListToIPFSDidStart(contact))

            // Keep passing the updated contact forward
            return self.api.add(file: newSendListURL).then { ($0, updatedContact) }
        }.then { addFileFesponse, contact -> Promise<(PublishResponse, Contact)> in
            self.eventCallback?(.publishingFileListToIPNSDidStart(contact))

            let sendListHash = addFileFesponse.hash
            let updatedSendList = contact.sendList.updatingHash(sendListHash)
            let updatedContact = contact.updatingSendList(updatedSendList)

            // Keep passing the updated contact forward
            return self.api.publish(arg: sendListHash, key: sendAddress.keypairName).then { ($0, updatedContact) }
        }.then { _, contact in
            // Persist the changes only after re-publishing the share list
            self.persistentStore.createOrUpdateContact(contact)

            return Promise(value: contact)
        }.catch { error in
            let horizonError: HorizonError = error is HorizonError
                ? error as! HorizonError : HorizonError.shareOperationFailed(reason: .unknown(error))
            self.eventCallback?(.errorEvent(horizonError))
        }
    }

}

// MARK: - Files Functionality (Inbound)

/**
 An extension which groups all related inbound file sharing functionality
 into one place.
 */
public extension Model {

    /**
     Returns an unordered list of received files and their associated contacts.
     */
    public var receivedFiles: [(File, Contact)] {
        return persistentStore.contacts.flatMap( { contact in
            return contact.receiveList.files.map { ($0, contact) }
        })
    }

    public func file(matching hash: String) -> File? {
        let matches = receivedFiles.filter { file, contact in
            return file.hash == hash
        }

        return matches.first?.0
    }

    public func data(for file: File) -> Promise<Data> {
        guard let hash = file.hash else {
            return Promise<Data>(error: HorizonError.fileOperationFailed(reason: .fileHashNotSet))
        }

        return firstly {
            return self.api.cat(arg: hash)
        }.catch { error in
            let horizonError: HorizonError = error is HorizonError
                ? error as! HorizonError : HorizonError.fileOperationFailed(reason: .unknown(error))
            self.eventCallback?(.errorEvent(horizonError))
        }
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
        return firstly {
            when(fulfilled: contacts.map({ contact -> Promise<(Contact, (String, Data)?)> in
                self.eventCallback?(.resolvingReceiveListDidStart(contact))

                guard let receiveAddress = contact.receiveAddress else {
                    return Promise(value: (contact, nil))
                }

                return firstly {
                    self.api.resolve(arg: receiveAddress, recursive: true)
                }.then { resolveResponse -> Promise<(Contact, (String, Data)?)> in
                    let receiveListHash = resolveResponse.path
                    return self.api.cat(arg: receiveListHash).then { data in
                        // Keep passing the contact forward, along with the new receive list data
                        (contact, (receiveListHash, data))
                    }
                }.recover { error in
                    Promise(value: (contact, nil))
                }
            }))
        }.then { syncResponses in
            return syncResponses.map{ (contact, maybeReceiveListData) in
                guard let receiveListData = maybeReceiveListData else {
                    let error: HorizonError
                    if contact.receiveAddress == nil {
                        error = HorizonError.syncOperationFailed(reason: .receiveAddressNotSet)
                    } else {
                        error = HorizonError.syncOperationFailed(reason: .failedToRetrieveSharedFileList)
                    }

                    return SyncState.failed(contact: contact, error: error)
                }
                let (receiveListHash, data) = receiveListData

                self.eventCallback?(.processingReceiveListDidStart(contact))

                if let files = try? JSONDecoder().decode([File].self, from: data) {
                    let updatedContact = contact.updatingReceiveList(FileList(hash: receiveListHash, files: files))

                    self.persistentStore.createOrUpdateContact(updatedContact)
                    self.eventCallback?(.propertiesDidChange(updatedContact))

                    return SyncState.synced(contact: updatedContact, oldValue: contact)
                } else {
                    let error = HorizonError.syncOperationFailed(reason: .invalidJSONForIPFSObject(receiveListHash))
                    return SyncState.failed(contact: contact, error: error)
                }
            }
        }

    }

}

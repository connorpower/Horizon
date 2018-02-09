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

    // MARK: - Constants

    struct Constants {
        static let keypairPrefix = "com.semantical.Horizon.contact"
    }

    // MARK: - Properties

    private let persistentStore: PersistentStore

    private let api: IPFSAPI

    private let eventCallback: ((Event) -> Void)?

    private var syncState = [(receiveHashList: String, contact: Contact)]()

    // MARK: - Initialization

    public init(api: IPFSAPI, persistentStore: PersistentStore, eventCallback: ((Event) -> Void)?) {
        self.api = api
        self.persistentStore = persistentStore
        self.eventCallback = eventCallback
    }

    // MARK: - API

    public func sync() {
        guard syncState.isEmpty else { return }

        let newSyncState = persistentStore.contacts.map({ contact -> (receiveHashList: String, contact: Contact)? in
            guard let receiveAddress = contact.receiveAddress else {
                return nil
            }
            return (receiveAddress, contact)
        }).flatMap( {$0} )

        guard !newSyncState.isEmpty else {
            return
        }

        syncState += newSyncState
        eventCallback?(.syncDidStart)

        for (receiveAddress, contact) in syncState {
            eventCallback?(.resolvingReceiveListDidStart(contact))

            firstly {
                return self.api.resolve(arg: receiveAddress, recursive: true)
            }.then { response in
                try self.getFileList(from: contact, at: response.path)
            }.catch { error in
                self.eventCallback?(.errorEvent(HorizonError.syncFailed(reason: .unknown(error))))
            }
        }
    }

    public func add(fileURLs: [URL], to contact: Contact) {
        // TODO: Add files in loop using when(fulfilled:) and only upload new fileList when all are added
        for url in fileURLs {
            eventCallback?(.addingFileToIPFSDidStart(File(name: url.lastPathComponent, hash: nil)))

            firstly {
                return self.api.add(file: url)
            }.then { response in
                let newFile = File(name: response.name, hash: response.hash)
                let sendListWithoutDuplicates = Array(Set(contact.sendList.files + [newFile]))
                let sendList = FileList(hash: nil, files: sendListWithoutDuplicates)

                var updatedContact = contact
                updatedContact.sendList = sendList
                self.persistentStore.createOrUpdateContact(updatedContact)

                // WARNING: This will likely fail if multiple concurrent attempts are performed
                // at once. Move commands into a background thread and perform in a blocking
                // synchronious manner
                //
                try self.sendFileList(to: contact)
            }.catch { error in
                self.eventCallback?(.errorEvent(HorizonError.addFileFailed(reason: .unknown(error))))
            }
        }
    }

    // MARK: Private Functions

    private func getFileList(from contact: Contact, at path: String) throws {
        eventCallback?(.downloadingReceiveListDidStart(contact))

        firstly {
            return api.cat(arg: path)
        }.then { data in
            self.eventCallback?(.processingReceiveListDidStart(contact))

            if let files = try? JSONDecoder().decode([File].self, from: data) {
                var updatedContact = contact
                updatedContact.receiveList = FileList(hash: path, files: files)
                self.persistentStore.createOrUpdateContact(updatedContact)

                self.eventCallback?(.propertiesDidChange(contact))
            } else {
                throw HorizonError.retrieveFileListFailed(reason: .invalidJSONAtPath(path))
            }
        }.always {
            self.removeContactFromSyncState(contact)
        }
    }

    private func sendFileList(to contact: Contact) throws {
        guard let data = try? JSONEncoder().encode(contact.sendList.files) else {
            throw HorizonError.sendFileListFailed(reason: .failedToEncodeFileList)
        }

        guard let tempDir = try? FileManager.default.url(for: .itemReplacementDirectory,
                                                         in: .userDomainMask,
                                                         appropriateFor: URL(fileURLWithPath: "/"),
                                                         create: true) else {
            throw HorizonError.sendFileListFailed(reason: .failedToCreateTemporaryDirectory)
        }

        let temporaryFile = tempDir.appendingPathComponent(UUID().uuidString + ".json")
        do {
            try data.write(to: temporaryFile)
        } catch {
            throw HorizonError.sendFileListFailed(reason: .failedToWriteTemporaryFile(temporaryFile))
        }

        eventCallback?(.addingProvidedFileListToIPFSDidStart(contact))

        firstly {
            return api.add(file: temporaryFile)
        }.then { (addFileFesponse: AddResponse) -> Promise<PublishResponse> in
            self.eventCallback?(.publishingFileListToIPNSDidStart(contact))

            return self.api.publish(arg: addFileFesponse.hash, key: contact.sendAddress?.keypairName)
        }.then { (publishResponse: PublishResponse) -> Void in
            var updatedContact = contact
            updatedContact.sendList = FileList(hash: publishResponse.value, files: contact.sendList.files)
            self.persistentStore.createOrUpdateContact(updatedContact)
        }.recover { error -> Void in
            throw HorizonError.sendFileListFailed(reason: .unknown(error))
        }
    }

    private func removeContactFromSyncState(_ contact: Contact) {
        syncState = syncState.filter({ $0.contact.identifier != contact.identifier })

        if syncState.isEmpty {
            eventCallback?(.syncDidEnd)
        }
    }

}

// MARK: - Contacts

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
        let keypairName = "\(Constants.keypairPrefix).\(name)"

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
        let keypairName = "\(Constants.keypairPrefix).\(name)"

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
     - paramter newName: The new display name for the contact.
     - returns: Returns either a promise which, when fulfilled, will contain
     the new `Contact` object or require handling of an
     `HorizonError.contactOperationFailed` error.
     */
    public func renameContact(_ name: String, to newName: String) -> Promise<Contact> {
        let keypairName = "\(Constants.keypairPrefix).\(name)"
        let newKeypairName = "\(Constants.keypairPrefix).\(newName)"

        return firstly {
            return self.api.listKeys()
        }.then { listKeysResponse  -> Promise<RenameKeyResponse> in
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
            guard let contact = self.contact(named: name) else {
                throw HorizonError.contactOperationFailed(reason: .contactDoesNotExist)
            }

            let sendAddress = SendAddress(address: renameKeyResponse.id, keypairName: renameKeyResponse.now)
            let updatedContact = contact.updatingDisplayName(newName).updatingSendAddress(sendAddress)

            self.persistentStore.createOrUpdateContact(updatedContact)
            self.eventCallback?(.propertiesDidChange(contact))
            return Promise(value: contact)
        }.catch { error in
            let horizonError: HorizonError = error is HorizonError
                ? error as! HorizonError : HorizonError.contactOperationFailed(reason: .unknown(error))
            self.eventCallback?(.errorEvent(horizonError))
        }
    }

}

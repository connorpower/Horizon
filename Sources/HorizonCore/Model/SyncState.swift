//
//  SyncState.swift
//  HorizonCore
//
//  Created by Connor Power on 23.02.18.
//

import Foundation

/**
 A simple enum which encapsulates the sync state of a contact.
 */
public enum SyncState {

    /**
     Indicates that the sync succeeded. Both the new value
     of the contact and the old value before the sync are
     included. This provides a mechanism by which the sync changes
     can be diffed.
     */
    case synced(contact: Contact, oldValue: Contact)

    /**
     Indicates that the sync failed. The value of the associated
     data remains the old value of the contact (which is also
     equal to the current value of the contact in this case).
     */
    case failed(contact: Contact, error: HorizonError)

}

//
//  ContactsHelp.swift
//  horizon
//
//  Created by Connor Power on 23.02.18.
//

import Foundation

struct ContactsHelp: HelpProvider {

    // MARK: - Constants

    static let longHelp = """
    USAGE
      horizon contacts - Create and manage Horizon contacts

    SYNOPSIS
      horizon contacts

    DESCRIPTION

      'horizon contacts add' adds a new contact for usage with Horizon.
      An address for the send channel will be immediately created. This address
      consists of an IPNS hash and can be shared with the contact to allow
      them to receive files from you.
      The contact should run the same procedure on their side and provide you
      with the address of their shared list.
      This becomes the receive-address which you can set manually later using
      'horizon contacts set-receive-addr <name> <receive-address>'

        > horizon contacts add mmusterman
        > horizon contacts set-rcv-addr mmusterman QmSomeHash

      'horizon contacts ls' lists the available contacts.

        > horizon contacts ls
        joe
        mmusterman

      'horizon contacts info <name>' prints a given contact to the screen,
      showing the current values for the send address and receive address.

        > horizon contacts info mmusterman
        mmusterman
        Send address:     QmSomeHash
        Receive address:  QmSomeHash
        IPFS keypair:     com-semantical.horizon.mmusterman

        joe
        Send address:     QmSomeHash
        Receive address:  QmSomeHash
        IPFS keypair:     com-semantical.horizon.joe

      'horizon contacts rm <name>' removes a given contact from Horizon.
      All files shared with the contact until this point remain available to
      the contact.

        > horizon contacts rm mmusterman

      'horizon contacts rename <name> <new-name>' renames a given contact
      but otherwise keeps all information and addresses the same.

        > horizon contacts rename mmusterman max

      'horizon contacts set-rcv-addr <name> <hash>' sets the receive address
      for a given contact. The contact should provide you with this address –
      the result of them adding you as a contact to their horizon instance.

        > horizon contacts set-rcv-addr mmusterman QmSomeHash

      SUBCOMMANDS
        horizon contacts help                          - Displays detailed help information
        horizon contacts add <name>                    - Create a new contact
        horizon contacts ls                            - List all contacts
        horizon contacts info <name>                   - Prints contact and associated details
        horizon contacts rm <name>                     - Removes contact
        horizon contacts rename <name> <new-name>      - Renames contact
        horizon contacts set-rcv-addr <name> <hash>    - Sets the receive address for a contact

        Use 'horizon contacts <subcmd> --help' for more information about each command.

    """

    static let shortHelp = """
    USAGE
      horizon contacts - Create and manage Horizon contacts

    SYNOPSIS
      horizon contacts

    SUBCOMMANDS
        horizon contacts help                          - Displays detailed help information
        horizon contacts add <name>                    - Create a new contact
        horizon contacts ls                            - List all contacts
        horizon contacts info [<name>]                 - Prints contact and associated details
        horizon contacts rm <name>                     - Removes contact
        horizon contacts rename <name> <new-name>      - Renames contact
        horizon contacts set-rcv-addr <name> <hash>    - Sets the receive address for a contact

        Use 'horizon contacts <subcmd> --help' for more information about each command.

    """

}

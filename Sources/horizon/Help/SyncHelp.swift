//
//  SyncHelp.swift
//  horizon
//
//  Created by Connor Power on 23.02.18.
//

import Foundation

struct SyncHelp: HelpProvider {

    static let longHelp = """
    USAGE
      horizon sync - Sync the shared files from horizon contacts

    SYNOPSIS
      horizon sync

    DESCRIPTION

      'horizon sync' syncs the lists of shared files from your horizon
      contacts. Until this command is run, the newly shared files from
      other contacts are not visible in the local horizon instance.

          > horizon sync
          contact-x: synced
          contact-y: failed (receive address not set)
          contact-z: synced

          Set a receive address using `horizon contacts set-rcv-addr <contact-name> <receive-hash>`

      Note that a sync can take some quite some time. It's also important
      that your contacts are online and connected to a network.

      SUBCOMMANDS
        horizon sync help    - Displays detailed help information
        horizon sync         - Sync the shared files from horizon contacts

        Use 'horizon sync <subcmd> --help' for more information about each command.

    """

    static let shortHelp = """
    USAGE
      horizon sync - Sync the shared files from horizon contacts

    SYNOPSIS
      horizon sync

      SUBCOMMANDS
        horizon sync help    - Displays detailed help information
        horizon sync         - Sync the shared files from horizon contacts

        Use 'horizon sync <subcmd> --help' for more information about each command.

    """

}

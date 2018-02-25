//
//  FilesHelp.swift
//  horizon
//
//  Created by Connor Power on 23.02.18.
//

import Foundation

struct FilesHelp: HelpProvider {

    // MARK: - HelpProvider Protocol

    static let longHelp = """
    USAGE
      horizon files - Manipulate files in horizon.

    SYNOPSIS
      horizon files

    DESCRIPTION

      'horizon files add' adds a new file to be shared with a contact.
      The file will be added to IPFS.

        > horizon shares add mmustermann '~/Desktop/The Byzantine Generals Problem.pdf'

      'horizon shares rm <contact-name> <file>' unshares a file with
      the given contact.

        > horizon shares rm mmustermann 'The Byzantine Generals Problem.pdf'

      Note that unsharing a file is not a security mechanism. There is no
      guarantee that your contact will receive the updated file list sans
      the removed file, or that the contact could not simply access the file
      via its direct IPFS hash.

      'horizon files ls [<contact>]' lists all files which you have
      sent or received, optionally restricted to a single contact.

        > horizon files ls
        mmusterman
          sent
            📤 'The Byzantine Generals Problem.pdf'
            📤 'This is Water, David Foster Wallace.pdf'
          received:
            📥 'IPFS - Content Addressed, Versioned, P2P File System (DRAFT 3).pdf'

        jbloggs
          sent
            (no files)
          received
            📥 'Bitcoin: A Peer-to-Peer Electronic Cash System, Satoshi Nakamoto.pdf'

      You may optionally filter by only a given contact.

        > horizon files ls jbloggs
          sent
            (no files)
          received
            📥 'Bitcoin: A Peer-to-Peer Electronic Cash System, Satoshi Nakamoto.pdf'

      'horizon files cat <contact> <file>' outputs the contents of a file to the
      command line. Care should be taken with binary files, as the shell may
      interpret byte sequences in unpredictable ways. This command is most
      useful when combined with a pipe.

        > horizon files cat mmustermann 'The Byzantine Generals Problem.pdf' | gzip > received_file.gzip

      'horizon files cp <contact> <file> <target-file>' copies the contents
      of a file to a location on the local machine. If <target-file> is a directory,
      the actual file will be written with it's Horizon name inside the directory.
      The following command would copy a file from Horizon onto your desktop.

        > horizon files cp mmustermann 'The Byzantine Generals Problem.pdf' ~/Desktop

      SUBCOMMANDS
        horizon files help                                  - Displays detailed help information
        horizon files share <contact> <file>                - Adds a new file to be shared with a contact
        horizon files unshare <contact> <file>              - Unshares a file which was shared with a contact
        horizon files ls [<contact>]                        - Lists all files (optionally filtered by a given contact)
        horizon files cat <contact> <file>                  - Outputs the contents of a file to the command line
        horizon files cp <contact> <file> <target-file>     - Copies a file to a location on the local machine

        Use 'horizon files <subcmd> --help' for more information about each command.

    """

    static let shortHelp = """
    USAGE
      horizon files - Manipulate files shared with you by Horizon contacts

    SYNOPSIS
      horizon files

      SUBCOMMANDS
        horizon files help                                  - Displays detailed help information
        horizon files share <contact> <file>                - Adds a new file to be shared with a contact
        horizon files unshare <contact> <file>              - Unshares a file which was shared with a contact
        horizon files ls [<contact>]                        - Lists all files (optionally filtered by a given contact)
        horizon files cat <contact> <file>                  - Outputs the contents of a file to the command line
        horizon files cp <contact> <file> <target-file>     - Copies a file to a location on the local machine

        Use 'horizon files <subcmd> --help' for more information about each command.

    """

    // MARK: - Command Specific Properties

    static let commandShareHelp = """
    horizon files share <contact> <file>
      'horizon files share' adds a new file to be shared with a contact.

        > horizon files share mmustermann '~/Desktop/The Byzantine Generals Problem.pdf'

    """

    static let commandUnshareHelp = """
    horizon files unshare <contact> <file>
      'horizon files unshare <contact> <hash>' unshares a file with
      the given contact.

      Note that unsharing a file is not a security mechanism. There is no
      guarantee that your contact will receive the updated file list sans
      the removed file, or that the contact could not simply access the file
      via its direct IPFS hash.

        > horizon files unshare mmustermann 'The Byzantine Generals Problem.pdf'

    """

    static let commandLsHelp = """
    horizon files ls [<contact>]
      'horizon files ls [<contact>]' lists all files you have received,
      optionally restricted to a single contact.

        > horizon files ls
        mmusterman
          sent
            📤 'The Byzantine Generals Problem.pdf'
            📤 'This is Water, David Foster Wallace.pdf'
          received:
            📥 'IPFS - Content Addressed, Versioned, P2P File System (DRAFT 3).pdf'

        jbloggs
          sent
            (no files)
          received
            📥 'Bitcoin: A Peer-to-Peer Electronic Cash System, Satoshi Nakamoto.pdf'

    """

    static let commandCatHelp = """
    horizon files cat <contact> <file>
      'horizon files cat <contact> <file>' outputs the contents of a file to the
      command line. Care should be taken with binary files, as the shell may
      interpret byte sequences in unpredictable ways. Most useful combined with
      a pipe.

        > horizon files cat mmustermann 'The Byzantine Generals Problem.pdf' | gzip > received_file.gzip

    """

    static let commandCpHelp = """
    horizon files cp <contact> <file> <target-file>
      'horizon files cp <contact> <file> <target-file>' copies the contents of a
      received file to a given location on the local machine. If <target-file>
      is a directory, the actual file will be written with it's Horizon name
      inside the directory. The following command would copy a file from
      Horizon to your desktop.

        > horizon files cp mmustermann 'The Byzantine Generals Problem.pdf' ~/Desktop

    """

}

//
//  DaemonHelp.swift
//  horizon
//
//  Created by Connor Power on 24.02.18.
//

import Foundation

struct DaemonHelp: HelpProvider {

    static let longHelp = """
    USAGE
      horizon daemon - Start or stop the background horizon process

    SYNOPSIS
      horizon daemon

    DESCRIPTION

      'horizon daemon start' starts the background daemon. The background
      daemon remains running so that contacts can access your shared files.

      The root directory for the daemon is located at `~/.horizon/<identity>`.
      If no particular identity was provided to horizon with the `--identity=`
      flag, then the root for the daemon will be `~/.horizon/default`.

      If the daemon hangs for some reason, the PID can be found in written
      to a file at `~/.horizon/<identity>/PID`, from which you can issue a
      manual `kill` command.

        > horizon daemon start
        Started 🤖
        > horizon daemon status
        Running (PID: 12345) 🤖

        > horizon daemon stop
        Stopped 💀
        > horizon daemon status
        Stopped  💀

      'horizon daemon status' prints the status of the background daemon.
      'horizon daemon stop' stops the background daemon.

      'horizon daemon ls' lists the status of the daemon for each identity.

        > horizon daemon ls
        'default': Running (PID: 12345) 🤖
        'work': Running (PID: 67890) 🤖
        'test': Stopped 💀

      SUBCOMMANDS
        horizon daemon help     - Displays detailed help information
        horizon daemon start    - Starts the horizon daemon in the background
        horizon daemon status   - Prints the current status of the background daemon
        horizon daemon ls       - Lists the status of the daemons for each identity
        horizon daemon stop     - Starts the horizon daemon in the background

        Use 'horizon daemon <subcmd> --help' for more information about each command.

    """

    static let shortHelp = """
    USAGE
      horizon daemon - Start or stop the background horizon process

    SYNOPSIS
      horizon daemon

      SUBCOMMANDS
        horizon daemon help     - Displays detailed help information
        horizon daemon start    - Starts the horizon daemon in the background
        horizon daemon status   - Prints the current status of the background daemon
        horizon daemon ls       - Lists the status of the daemons for each identity
        horizon daemon stop     - Starts the horizon daemon in the background

        Use 'horizon daemon <subcmd> --help' for more information about each command.

    """

}

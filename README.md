[![build status](https://www.bitrise.io/app/5fb60dd6ad39288f/status.svg?token=7gnnEefvTpNA4obgeJXW8w)](https://www.bitrise.io/app/5fb60dd6ad39288f)

# Horizon

A fileshare for the decentralized web.

## Getting Started

These instructions will get you a copy of the project up and running on your
local machine for development and testing purposes. See deployment for notes
on how the beta testing pool is managed.

### Horizon Workspace

Work from the `Horizon.xcworkspace` Workspace. This workspace contains all
relevant sub-projects and correctly exposes build dependencies.

### Swift Package Manager

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for
automating the distribution of Swift code and is integrated into the `swift`
compiler. It is in early development, but Horizon does support its use. The
Swift Package manager doesn't yet support Cocoa GUI apps, so its use in this
project comes with some caveats.

The horizon is Swift Package Manger based and the Xcode project 'horizon'
is autogenerated. To get started with the project on a fresh machine, run:

    ./spm-init.sh

This command will check out the Swift Package Manager managed dependencies
and regenerate the Xcode project file.

The Horizon' project on the other hand is a regular Cocoa GUI app. As such,
it lacks Swift Package Manager support and the Xcode Project 'Horizon' is
manually managed. To combine the Cocoa GUI app with the libraries managed by
the Swift Package Manger, we use an umnbrella Xcode Workspace 'Horizon' as a
pragmatic means of acessing the SPM managed libraries from the Cocoa App.

#### But why?

Cocoapods doesn't support Swift static libraries – a necessity for the command
line app. The Swift Package Manager doesn't support either Cocoa or iOS Apps.
Neither offers an optimial soultion, but the Swift Package Manager is likely
the best long-term solution.

#### Dependency Management

Dependencies are managed by the swift package manager as normal. Simply run
`swift package update` to automatically update the dependencies listed in
the `Package.swift` manifest file.

### Running the app

If IPFS is not yet installed on your machine, you can install it using the
excellent [Homebrew](https://brew.sh) package manager.

```
brew install ipfs
```

Be sure to start IPFS before running Horizon.

```
ipfs daemon
```

Run Horizon, observing the log window as necessary.

## Logging

For logging, we use Apple's new unified logging framework. This allows
configuration of the logging granularity from the OS without requiring
a re-compile or re-configuration of the app.

The various levels are:

- off
- default
- info
- debug

Example for the command line tool:

    sudo log config --mode "level:info" --subsystem com.semantical.horizon

Example for the macOS App:

    sudo log config --mode "level:info" --subsystem com.semantical.Horizon

## Running the tests

Automated tests exist only in the form of unit tests run by the continuous
integration server. Due to the distributed nature of the app few other tests
make sense.

## Database

Horizon uses the inbuilt macOS UserDefaults as a simple form of persistence
for contacts and file lists. During development, the contents of UserDefaults
can be easily inspected on the terminal:

    # Show all entries for the command line tool
    > defaults read horizon

    # Show the contact list for the default identity
    > defaults read horizon com.semantical.Horizon.default.contactList

Horizon supports multiple independent and simultaneous identities. Presuming
you have (in addition to the 'default' identity) a 'work' identitiy:

    # Show the contact list for the 'work' identity
    > defaults read horizon com.semantical.Horizon.work.contactList

Care is taken to ensure that the entries are JSON formatted strings, so the
following command will be more useful in most circumstances.

    > output=$(defaults read horizon com.semantical.Horizon.default.contactList) && echo -n $output | jsonlint

Why not just a straightforward pipe? If the key is not present in the UserDefaults
we end up trying to feed gabarge into `jsonLint`.


## Built With

* [Swift Package Manager](https://swift.org/package-manager/) – The Package Manager for the Swift Programming Language
* [SwiftLint](https://github.com/realm/SwiftLint) – A tool to enforce Swift style and conventions
* [PromiseKit](https://github.com/mxcl/PromiseKit) – Promises for Swift & ObjC
* [Alamofire](https://github.com/Alamofire/Alamofire) – Elegant HTTP Networking in Swift
* [Bitrise](https://www.bitrise.io) – Continuous Integration
* [App Center](https://appcenter.ms) – Crash Reporting

## Versioning

We use [Semantic Versioning](http://semver.org/). For the versions available,
see the [tags on this repository](https://github.com/connorpower/Horizon/tags).

## Authors

* **Connor Power** – *Initial work* – [connorpower](https://github.com/connorpower)
* **Jürgen Schweizer** – *Initial work* – [jschweizer](https://github.com/jschweizer)

## License

Until further notice, this project is closed source.

## Acknowledgments

* This project would not have been possible without the excellent work
  being done in the [IPFS](https://github.com/ipfs/ipfs) project.

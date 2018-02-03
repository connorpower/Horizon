[![Master build status](https://build.appcenter.ms/v0.1/apps/698105ed-4847-4884-a9b2-3c22ae326101/branches/master/badge)](https://appcenter.ms)

# Horizon

An encrypted fileshare for the decentralized web.

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

The horizon-cli is Swift Package Manger based. The Xcode project 'horizon-cli'
can therefore simply be regenerated:

    swift package generate-xcodeproj --xcconfig-overrides ./Configuration.xcconfig

The HorizonApp project is a regular Cocoa GUI app. As such, it lacks Swift
Package Manager support and the Xcode Project 'HorizonApp' is manually managed.

To combine the Cocoa GUI app with the libraries managed by the Swift Package
Manger, we use an umnbrella Xcode Workspace 'Horizon' as a pragmatic means of
acessing the SPM managed libraries from the Cocoa App.

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

## Running the tests

Automated tests exist only in the form of unit tests run by the continuous
integration server. Due to the distributed nature of the app few other tests
make sense.

## Deployment

Horizon is deployed amongst testers using [App Center](https://appcenter.ms).

App Center is responsible for:

- Building Horizon automatically based on new commits to the master or
  develop branches.
- Automatically emailing contributors with a download link whenever a new
  release is merged into master.
- Receiving crash reports from testers.
- Storing debug symbols and automatically symbolicating crash reports.
- Collecting rudimentary analytics.

## Built With

* [Swift Package Manager](https://swift.org/package-manager/) - Dependency Management
* [SwiftLint](https://github.com/realm/SwiftLint) - Swift Linter
* [App Center](https://appcenter.ms) - Continuous Integration

## Versioning

We use [Semantic Versioning](http://semver.org/). For the versions available,
see the [tags on this repository](https://github.com/connorpower/Horizon/tags).

## Authors

* **Connor Power** - *Initial work* - [connorpower](https://github.com/connorpower)
* **Jürgen Schweizer** - *Initial work* - [jschweizer](https://github.com/jschweizer)

## License

Until further notice, this project is closed source.

## Acknowledgments

* This project would not have been possible without the excellent work
  being done in the [IPFS](https://github.com/ipfs/ipfs) project.

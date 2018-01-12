[![Master build status](https://build.appcenter.ms/v0.1/apps/698105ed-4847-4884-a9b2-3c22ae326101/branches/master/badge)](https://appcenter.ms)

# Horizon

An encrypted fileshare for the decentralized web.

## Getting Started

These instructions will get you a copy of the project up and running on your
local machine for development and testing purposes. See deployment for notes
on how the beta testing pool is managed.

### Prerequisites

Cocoapods is used for dependency management. Cocoapods is not required to
build the app as all dependencies have been checked into the repository.
You only need to install Cocoapods if you are actively developing Horizon.

This project integrates [SwiftLint](https://github.com/realm/SwiftLint) as
a build step to ensure consistency among contributors and to detect common
pitfalls. SwiftLint runs automatically during compilation.

Under the hood, Horizon leverages [IPFS](https://github.com/ipfs/ipfs)
for the distributed storage and data transfer mechanism. IPFS *is* required
on the local system, and should be running before starting Horizon.

```
# Required for development only
brew install cocoapods
brew install swiftlint
```

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

* [Xcode](https://developer.apple.com/xcode/) - Integrated Development Environment
* [Cocoapods](https://cocoapods.org) - Dependency Management
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

// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "horizon-cli",
    products: [
        .executable(name: "horizon-cli", targets: ["horizon-cli"]),
        .library(name: "HorizonCore", type: .static, targets: ["HorizonCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/connorpower/IPFSWebService.git", from: "4.1.1"),
        .package(url: "https://github.com/mxcl/PromiseKit.git", from: "4.5.0"),
    ],
    targets: [
        .target(
            name: "horizon-cli",
            dependencies: ["HorizonCore"]),
        .target(
            name: "HorizonCore",
            dependencies: ["IPFSWebService"]),
        .testTarget(
            name: "HorizonCoreTests",
            dependencies: ["HorizonCore"]),
    ]
)

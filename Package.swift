// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "Horizon",
    products: [
        .executable(name: "horizon-cli", targets: ["horizon-cli"]),
        .library(name: "HorizonCore", type: .static, targets: ["HorizonCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/connorpower/IPFSWebService.git", from: "3.0.0")
    ],
    targets: [
        .target(
            name: "horizon-cli",
            dependencies: ["HorizonCore"]),
        .target(
            name: "HorizonCore",
            dependencies: ["IPFSWebService"]),
    ]
)

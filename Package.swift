// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "horizon",
    products: [
        .executable(name: "horizon", targets: ["horizon"]),
        .library(name: "HorizonCore", type: .static, targets: ["HorizonCore"])
    ],
    dependencies: [
        .package(url: "git@github.com:connorpower/IPFSWebService.git", .branch("4.1.1")),
        .package(url: "https://github.com/mxcl/PromiseKit.git", from: "4.5.0")
    ],
    targets: [
        .target(
            name: "horizon",
            dependencies: ["HorizonCore"]),
        .target(
            name: "HorizonCore",
            dependencies: ["IPFSWebService"]),
        .testTarget(
            name: "HorizonCoreTests",
            dependencies: ["HorizonCore"])
    ]
)

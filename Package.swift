// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NVMKeychain",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .tvOS(.v15),
        .watchOS(.v8)
    ],
    products: [
        .library(
            name: "NVMKeychain",
            targets: ["NVMKeychain"]),
    ],
    targets: [
        .target(
            name: "NVMKeychain"),
        .testTarget(
            name: "NVMKeychainTests",
            dependencies: ["NVMKeychain"]),
    ]
)

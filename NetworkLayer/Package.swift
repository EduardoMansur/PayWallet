// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NetworkLayer",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8)
    ],
    products: [
        .library(
            name: "NetworkLayer",
            targets: ["NetworkLayer"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "NetworkLayer",
            dependencies: []),
        .testTarget(
            name: "NetworkLayerTests",
            dependencies: ["NetworkLayer"]),
    ]
)

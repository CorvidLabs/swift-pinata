// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "swift-pinata",
    platforms: [
        .iOS(.v15),
        .watchOS(.v8),
        .macOS(.v12),
        .tvOS(.v15),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "Pinata",
            targets: ["Pinata"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-docc-plugin",
            from: "1.4.0"
        )
    ],
    targets: [
        .target(
            name: "Pinata"
        ),
        .testTarget(
            name: "PinataTests",
            dependencies: ["Pinata"]
        )
    ]
)

// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let dependencies: [Target.Dependency] = [
    .product(name: "Logging", package: "swift-log"),
    .product(name: "ArgumentParser", package: "swift-argument-parser"),
    .product(name: "NIOCore", package: "swift-nio"),
    .product(name: "NIOPosix", package: "swift-nio"),
    .product(name: "NIOHTTP1", package: "swift-nio"),
    .product(name: "NIOFoundationCompat", package: "swift-nio"),
    .product(name: "_NIOFileSystem", package: "swift-nio"),
    .product(name: "NIOTransportServices", package: "swift-nio-transport-services"),
    .product(name: "NIOHTTPCompression", package: "swift-nio-extras"),
    .product(name: "swift-polis", package: "swift-polis"),
    .product(name: "NIOSSL", package: "swift-nio-ssl"),
]

let package = Package(
    name: "SearchService",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.63.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        .package(url: "https://github.com/apple/swift-nio-extras.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-nio-transport-services.git", from: "1.13.0"),
        .package(url: "https://github.com/ASTRO-POLIS/swift-polis.git", branch: "dev"),
        .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "2.26.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "SearchService",
            dependencies: dependencies
        ),
        .testTarget(
            name: "SearchServiceTests",
            dependencies: ["SearchService"] + dependencies
        )
    ]
)

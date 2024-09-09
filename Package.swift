// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CoreNetwork",
    platforms: [
        .iOS(SupportedPlatform.IOSVersion.v13),
        .macOS(SupportedPlatform.MacOSVersion.v10_15),
        .watchOS(SupportedPlatform.WatchOSVersion.v6),
        .tvOS(SupportedPlatform.TVOSVersion.v13)
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "CoreNetwork",
            targets: ["CoreNetwork"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.9.1")),
        .package(url: "https://github.com/kmisiura/OSLogger.git", from: "1.0.0"),
        .package(url: "https://github.com/jernejstrasner/SwiftCrypto.git", from: "1.0.1"),
        .package(url: "https://github.com/WeTransfer/Mocker.git", from: "2.3.0"),
        .package(url: "https://github.com/Flight-School/AnyCodable.git", from: "0.6.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "CoreNetwork",
            dependencies: ["Alamofire", "OSLogger", "SwiftCrypto", "AnyCodable"]),
        .testTarget(
            name: "CoreNetworkTests",
            dependencies: ["CoreNetwork", "Mocker"]),
    ]
)

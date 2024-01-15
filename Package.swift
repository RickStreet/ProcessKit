// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ProcessKit",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "ProcessKit",
            targets: ["ProcessKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/RickStreet/DoubleKit.git", from: "1.0.6"),
        .package(url: "https://github.com/RickStreet/AxisSpacing.git", from: "1.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "ProcessKit",
            dependencies: ["DoubleKit", "AxisSpacing"]),
        .testTarget(
            name: "ProcessKitTests",
            dependencies: ["ProcessKit","DoubleKit", "AxisSpacing"]),
    ]
)

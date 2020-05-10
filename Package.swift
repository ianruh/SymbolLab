// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SymbolLab",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "SymbolLab",
            targets: ["SymbolLab"]),
        .library(
            name: "SymbolLabTraining",
            targets: ["SymbolLabTraining"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
         .package(url: "../SymEngine", from: "0.0.1"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "SymbolLab",
            dependencies: ["SymEngine"]),
        .target(
            name: "SymbolLabTraining",
            dependencies: []),
        .testTarget(
            name: "SymbolLabTests",
            dependencies: ["SymbolLab"]),
    ]
)

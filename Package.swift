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
        .executable(
            name:"examples",
            targets: ["Examples"]),
        .library(
            name:"symEngineBackend",
            targets: ["SymEngineBackend"]),
        .library(
            name:"swiftBackend",
            targets: ["SwiftBackend"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(name: "SymEngine", url: "https://github.com/ianruh/SymEngine.swift", from: "0.0.2"),
        .package(url: "https://github.com/apple/swift-numerics", from: "0.0.8"),
        .package(url: "https://github.com/ianruh/LASwift.git", .branch("linux")),
        .package(url: "https://github.com/pvieito/PythonKit.git", .branch("master"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "SymbolLab",
            dependencies: [
                .product(name: "RealModule", package: "swift-numerics"),
                "LASwift"]),
        .target(
            name: "Examples",
            dependencies: ["SymbolLab",
                           "PythonKit",
                           "SwiftBackend"]),
        .target(
            name: "SymEngineBackend",
            dependencies: ["SymbolLab", "SymEngine",]
        ),
        .target(name: "SwiftBackend", dependencies: ["SymbolLab"]),
        .testTarget(
            name: "SymbolLabTests",
            dependencies: ["SymbolLab"]),
        .testTarget(
            name: "SwiftBackendTests",
            dependencies: ["SymbolLab", "SwiftBackend"]),
    ]
)

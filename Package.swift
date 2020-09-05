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
             name:"databaseUtility",
             targets: ["DatabaseUtility"]),
        .library(
                name:"symEngineBackend",
                targets: ["SymEngineBackend"]),
        .executable(
                name:"generateYoloData",
                targets: ["GenerateYoloData"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "../../SymEngine", from: "0.0.0"),
//        .package(url: "https://github.com/ianruh/SymEngine.swift", from: "0.0.2"),
        //.package(url: "https://github.com/vapor/postgres-kit.git", from: "2.0.0")
        .package(url: "https://github.com/apple/swift-numerics", from: "0.0.5"),
        .package(
            url: "https://github.com/ianruh/LASwift.git",
            .branch("linsolve")
        ),
        .package(url: "https://github.com/pvieito/PythonKit.git", .branch("master")),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.0.0"),
        .package(url: "https://github.com/KarthikRIyer/swiftplot.git", from: "2.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "SymbolLab",
            dependencies: [
                .product(name: "RealModule", package: "swift-numerics"),
                "LASwift"
        ]),
        .target(
            name: "Examples",
            dependencies: ["SymbolLab",
                           .product(name: "SwiftPlot", package: "swiftplot"),
                           .product(name: "SVGRenderer", package: "swiftplot"),
                           "SymEngineBackend"]),
        .target(
            name: "DatabaseUtility",
            dependencies: ["SymbolLab", "PythonKit"]),
        .target(
                name: "SymEngineBackend",
                dependencies: ["SymbolLab",
                               //.product(name: "SymEngine", package: "SymEngine.swift"),
                               "SymEngine",]
        ),
        .target(
            name: "GenerateYoloData",
            dependencies: ["SymbolLab",
                           "DatabaseUtility",
                           .product(name: "ArgumentParser", package: "swift-argument-parser")]),
        .testTarget(
            name: "SymbolLabTests",
            dependencies: ["SymbolLab"]),
    ]
)

// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import Foundation

var products: [Product] = [
    .library(
        name: "SymbolLab",
        targets: ["SymbolLab"]),
    .executable(
        name:"examples",
        targets: ["Examples"]),
    .library(
        name:"swiftBackend",
        targets: ["SwiftBackend"])
]

var dependencies: [PackageDescription.Package.Dependency] = [
    .package(url: "https://github.com/apple/swift-numerics", from: "0.0.8"),
    .package(url: "https://github.com/ianruh/LASwift.git", .branch("linux")),
    .package(url: "https://github.com/pvieito/PythonKit.git", .branch("master")),
    .package(url: "https://github.com/apple/swift-argument-parser", .branch("main")),
]

var targets: [Target] = [
    .target(
        name: "SymbolLab",
        dependencies: [
            .product(name: "RealModule", package: "swift-numerics"),
            "LASwift"]),
    .testTarget(
        name: "SymbolLabTests",
        dependencies: ["SymbolLab", "SwiftBackend"]),
    .target(name: "SwiftBackend",
        dependencies: ["SymbolLab"]),
    .testTarget(name: "SwiftBackendTests",
        dependencies: ["SymbolLab", "SwiftBackend"]),
    .target(
        name: "Examples",
        dependencies: ["SymbolLab",
                        "PythonKit",
                        "SwiftBackend",
                        .product(name: "ArgumentParser", package: "swift-argument-parser")])
]

#if SYMENGINE
    products.append(.library(name:"symEngineBackend",targets: ["SymEngineBackend"]))

    dependencies.append(.package(url: "https://github.com/ianruh/SymEngine.swift", from: "0.0.2"))

    targets.append(.target(name: "SymEngineBackend", dependencies: ["SymbolLab", "SymEngine"]))
#endif

let package = Package(
    name: "SymbolLab",
    products: products,
    dependencies: dependencies,
    targets: targets
)

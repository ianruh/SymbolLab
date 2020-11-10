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
]

var dependencies: [PackageDescription.Package.Dependency] = [
    .package(url: "https://github.com/apple/swift-numerics", from: "0.0.8"),
    .package(url: "https://github.com/ianruh/LASwift.git", .branch("linux")),
    .package(url: "https://github.com/pvieito/PythonKit.git", .branch("master"))
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
]

var examplesTarget: Target = .target(
        name: "Examples",
        dependencies: ["SymbolLab",
                        "PythonKit"])

#if SYMENGINE
    print("Symengine")
    products.append(.library(name:"symEngineBackend",targets: ["SymEngineBackend"]))

    dependencies.append(.package(url: "https://github.com/ianruh/SymEngine.swift", from: "0.0.2"))

    targets.append(.target(name: "SymEngineBackend", dependencies: ["SymbolLab", "SymEngine"]))

    examplesTarget.dependencies.append("SymEngineBackend")
    targets.append(examplesTarget)
#else
    print("SwiftBackend")
    products.append(.library(name:"swiftBackend",targets: ["SwiftBackend"]))

    targets.append(.target(name: "SwiftBackend", dependencies: ["SymbolLab"]))
    targets.append(.testTarget(name: "SwiftBackendTests",dependencies: ["SymbolLab", "SwiftBackend"]))

    examplesTarget.dependencies.append("SwiftBackend")
    targets.append(examplesTarget)
#endif

let package = Package(
    name: "SymbolLab",
    products: products,
    dependencies: dependencies,
    targets: targets
)

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
            name:"symbolTest",
            targets: ["SymbolTest"])//,
        // .executable(
        //     name:"databaseUtility",
        //     targets: ["DatabaseUtility"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
         .package(url: "../../SymEngine", from: "0.0.1"),
         //.package(url: "https://github.com/vapor/postgres-kit.git", from: "2.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "SymbolLab",
            dependencies: ["SymEngine"]),
        .target(
            name: "SymbolTest",
            dependencies: ["SymbolLab"]),
        //.target(name: "DatabaseUtility",
        //    dependencies: ["SymbolLab", "PostgresKit"]),
        .testTarget(
            name: "SymbolLabTests",
            dependencies: ["SymbolLab"]),
    ]
)

// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CoOpAttributes",
    platforms: [
        .macOS(.v10_14),
        .iOS(.v14),
        .tvOS(.v14)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "CoOpAttributes",
            targets: ["CoOpAttributes"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(name: "CoreDataModelDescription", url: "https://github.com/dmytro-anokhin/core-data-model-description", from: "0.0.10"),
//        .package(name: "SwiftProtobuf", url: "https://github.com/apple/swift-protobuf.git", from: "1.6.0"),

//        .package(name: "CoreDataModelDescription", url: "../core-data-model-description", from: "0.0.9"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "CoOpAttributes",
            dependencies: ["CoreDataModelDescription"]),
        .testTarget(
            name: "CoOpAttributesTests",
            dependencies: ["CoOpAttributes"]),
    ]
)


//
// 'CoreDataModelDescription' in target 'CoOpAttributes' requires explicit declaration; provide the name of the package dependency with '.package(name: "CoreDataModelDescription", url: "https://github.com/dmytro-anokhin/core-data-model-description", from: "0.0.9")'
//
//
// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "App",
    defaultLocalization: "en",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "App",
            targets: ["App"]),
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../Features"),
    ],
    targets: [
        .target(
            name: "App",
            dependencies: [
                "Core",
                .product(name: "About", package: "Features"),
                .product(name: "Home", package: "Features"),
                .product(name: "SavedItem", package: "Features")
            ],
            // plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")]
        )
    ]
)

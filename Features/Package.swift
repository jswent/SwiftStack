// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Features",
    defaultLocalization: "en",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "About",
            targets: ["About"]),
        .library(
            name: "SavedItem",
            targets: ["SavedItem"]),
        .library(
            name: "Home",
            targets: ["Home"]),
    ],
    dependencies: [
        .package(path: "../Core"),
    ],
    targets: [
        .target(
            name: "About",
            dependencies: [
                "Core"
            ],
            path: "Sources/Features/About",
            resources: [
                .process("Data/Licenses.plist")
            ],
            // plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")]
        ),
        .target(
            name: "SavedItem",
            dependencies: [
                "Core"
            ],
            path: "Sources/Features/SavedItem",
            // plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")]
        ),
        .target(
            name: "Home",
            dependencies: [
                "Core"
            ],
            path: "Sources/Features/Home",
            // plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")]
        )
    ],
)

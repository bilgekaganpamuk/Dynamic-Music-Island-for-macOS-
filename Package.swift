// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DynamicMusicIsland",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "DynamicMusicIsland",
            targets: ["DynamicMusicIsland"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "DynamicMusicIsland",
            dependencies: [],
            path: "Sources",
            exclude: ["Resources"],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .enableExperimentalFeature("StrictConcurrency=complete")
            ]
        ),
        .testTarget(
            name: "DynamicMusicIslandTests",
            dependencies: ["DynamicMusicIsland"],
            path: "Tests"
        )
    ]
)

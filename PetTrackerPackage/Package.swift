// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PetTrackerPackage",
    platforms: [
        .iOS(.v26),
        .watchOS(.v26)
    ],
    products: [
        // Main feature module containing all app logic
        .library(
            name: "PetTrackerFeature",
            targets: ["PetTrackerFeature"]
        ),
    ],
    dependencies: [
        // No external dependencies - all on-device processing
    ],
    targets: [
        // Main feature target
        .target(
            name: "PetTrackerFeature",
            dependencies: [],
            swiftSettings: [
                // Enable strict concurrency checking
                .enableExperimentalFeature("StrictConcurrency"),
                // Enable complete concurrency checking
                .enableUpcomingFeature("ConciseMagicFile"),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("BareSlashRegexLiterals"),
                .enableUpcomingFeature("ImplicitOpenExistentials"),
            ]
        ),

        // Test target
        .testTarget(
            name: "PetTrackerFeatureTests",
            dependencies: ["PetTrackerFeature"],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PetTrackerPackage",
    platforms: [
        .iOS(.v18),      // Will be updated to iOS 26 when creating Xcode project
        .watchOS(.v11)   // Will be updated to watchOS 26 when creating Xcode project
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

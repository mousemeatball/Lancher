// swift-tools-version: 6.0
import PackageDescription

// Lancher — a customizable full-screen app launcher for macOS (Launchpad alternative).
//
// Deployment target is kept at macOS 14 for now so it builds against stable AppKit/SwiftUI
// APIs. Production should raise this to .v26 (Tahoe) to adopt the native Liquid Glass design.
let package = Package(
    name: "Lancher",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Lancher", targets: ["Lancher"]),
        .library(name: "LancherCore", targets: ["LancherCore"]),
    ],
    targets: [
        // Thin executable: only the @main entry point lives here.
        .executableTarget(
            name: "Lancher",
            dependencies: ["LancherCore"],
            path: "Sources/Lancher"
        ),
        // All models, services, view models, and views — kept in a library so it is testable.
        .target(
            name: "LancherCore",
            path: "Sources/LancherCore"
        ),
        .testTarget(
            name: "LancherCoreTests",
            dependencies: ["LancherCore"],
            path: "Tests/LancherCoreTests"
        ),
    ]
)

// swift-tools-version: 6.0
import PackageDescription

// Lancher — a customizable full-screen app launcher for macOS (a Launchpad alternative).
//
// Targets macOS 26 Tahoe so we can adopt the native Liquid Glass design. Built entirely from
// scratch from public feature descriptions — contains no third-party code, icons, or trademarks.
//
// The deployment target uses the string form `.macOS("26.0")` so it resolves regardless of which
// `.vNN` enum cases the installed PackageDescription exposes.
let package = Package(
    name: "Lancher",
    platforms: [.macOS("26.0")],
    products: [
        .executable(name: "Lancher", targets: ["Lancher"]),
        .library(name: "LauncherKit", targets: ["LauncherKit"]),
    ],
    targets: [
        // Thin executable: bootstraps NSApplication + the menu-bar AppDelegate.
        .executableTarget(
            name: "Lancher",
            dependencies: ["LauncherKit"],
            path: "Sources/Lancher"
        ),
        // All models, services, view models, and views — kept in a library so it is testable.
        .target(
            name: "LauncherKit",
            path: "Sources/LauncherKit"
        ),
        .testTarget(
            name: "LauncherKitTests",
            dependencies: ["LauncherKit"],
            path: "Tests/LauncherKitTests"
        ),
    ]
)

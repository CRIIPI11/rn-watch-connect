// swift-tools-version:5.9
// Runs the WatchSessionController tests on macOS with `swift test` (see docs/adr/0001).
// Not part of the shipped pod: the podspec excludes this file and Tests/.

import PackageDescription

let package = Package(
    name: "WatchSession",
    platforms: [.macOS(.v13)],
    targets: [
        .target(
            name: "WatchSession",
            path: "Session"
        ),
        .testTarget(
            name: "WatchSessionTests",
            dependencies: ["WatchSession"],
            path: "Tests/WatchSessionTests"
        ),
    ]
)

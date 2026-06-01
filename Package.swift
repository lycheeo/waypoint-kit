// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "WaypointKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "WaypointKit",
            targets: ["WaypointKit"]
        ),
    ],
    targets: [
        .target(
            name: "WaypointKit"
        ),
        .executableTarget(
            name: "WaypointKitValidation",
            dependencies: ["WaypointKit"]
        ),
    ]
)

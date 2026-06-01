// swift-tools-version: 6.1

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
        .executable(
            name: "WaypointKitDemo",
            targets: ["WaypointKitDemo"]
        ),
    ],
    targets: [
        .target(
            name: "WaypointKit"
        ),
        .executableTarget(
            name: "WaypointKitDemo",
            dependencies: ["WaypointKit"]
        ),
        .executableTarget(
            name: "WaypointKitValidation",
            dependencies: ["WaypointKit"]
        ),
    ]
)

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
        .library(
            name: "WaypointKitSwiftUIDemo",
            targets: ["WaypointKitSwiftUIDemo"]
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
        .target(
            name: "WaypointKitSwiftUIDemo",
            dependencies: ["WaypointKit"],
            path: "Examples/WaypointKitSwiftUIDemo",
            exclude: ["README.md"]
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

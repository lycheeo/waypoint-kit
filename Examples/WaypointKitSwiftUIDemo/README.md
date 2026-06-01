# WaypointKit SwiftUI Demo

This target is a small SwiftUI example for ETA-style route editing.

It does not call a live map service and does not require API keys. The view uses `MockPOIProvider` to search a verified candidate, then builds a reviewable `RouteChangeProposal`.

Build it from the package root:

```bash
swift build
```

Use the example module from another package:

```swift
.product(name: "WaypointKitSwiftUIDemo", package: "waypoint-kit")
```

Then render `WaypointKitDemoView()` inside an app shell.

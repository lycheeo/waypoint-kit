# WaypointKit

AI-assisted route planning and waypoint editing for Swift apps.

WaypointKit is a Swift package for building itinerary editors where a model can understand route changes, but the app keeps control of real places, coordinates, diffs, and final state changes.

The package is extracted from ETA, a real iOS route-planning app, and focuses on the reusable core:

- waypoint models for route stops, stay time, selected state, POI metadata, and favorites
- route metrics, distance fallback, route diffing, and safe proposal narratives
- WGS-84 / GCJ-02 coordinate conversion for China map-provider integrations
- AI intent routing for small talk, trip inspiration, route creation, and route editing
- prompt builders and tool schemas for verified POI search before applying model-generated edits
- validation executable covering coordinate conversion, waypoint identity, route metrics, collection rules, route diffs, prompt generation, AI orchestration, and route-edit regression fixtures

## Install

Add the package to another Swift package:

```swift
.package(url: "https://github.com/lycheeo/waypoint-kit.git", from: "0.1.1")
```

Then depend on the library target:

```swift
.product(name: "WaypointKit", package: "waypoint-kit")
```

## Basic Usage

```swift
import WaypointKit

let current = [
    Waypoint(name: "People's Square", address: "Shanghai", latitude: 31.2304, longitude: 121.4737),
    Waypoint(name: "The Bund", address: "Shanghai", latitude: 31.2397, longitude: 121.4998)
]

let prompt = RouteListEditingPromptBuilder.userPromptForEdit(
    currentPoints: current,
    userPrompt: "Replace the final stop with a quieter riverside place",
    conversationTurns: []
)

let toolSchema = RouteListEditingToolSchemas.openAIEditToolSchema
let changes = RouteChangeDiffBuilder.changes(
    before: current,
    after: [
        current[0],
        Waypoint(name: "Xuhui Riverside", address: "Shanghai", latitude: 31.1808, longitude: 121.4639)
    ]
)
```

## Design Principle

Models should not invent route state.

WaypointKit separates:

- language understanding: classify intent and propose an edit
- provider verification: search real POI candidates through your provider
- state application: diff, validate, and apply only after confirmation

That separation is the main reason the project exists.

## Validate

This environment's Swift toolchain does not expose XCTest or Swift Testing modules, so the repository includes a framework-free validation executable:

```bash
swift build
swift run WaypointKitValidation
```

Expected output:

```text
WaypointKit validation passed (43 validation cases).
```

## Demo

Run the local demo without API keys or network access:

```bash
swift run WaypointKitDemo
```

It shows a verified candidate replacing a route stop, then prints the reviewable proposal, safety line, and distance fallback.

## Evals

WaypointKit includes public route-editing regression fixtures in [Fixtures/route-edit-regressions.json](Fixtures/route-edit-regressions.json). The validation executable decodes them and checks diff, narrative, usability, and warning behavior.

See [docs/EVALS.md](docs/EVALS.md) for the current evaluation surface and planned expansion.

## Status

This is an early open-source extraction from the ETA app. The first public milestone is a stable core toolkit, not a full navigation app.

See [ROADMAP.md](ROADMAP.md) for planned provider abstractions and expanded regression evaluation work.

See [docs/MAINTENANCE_EVIDENCE.md](docs/MAINTENANCE_EVIDENCE.md) for the public maintenance evidence and the local ETA extraction boundary.

# Testing Guide

This guide is for contributors who want to verify WaypointKit without private ETA code or service keys.

## Requirements

- macOS with a Swift toolchain that supports Swift tools version 6.1
- Git
- No map provider credentials
- No OpenAI or LLM provider credentials

## Quick Local Check

```bash
git clone https://github.com/lycheeo/waypoint-kit.git
cd waypoint-kit
swift build
swift run WaypointKitValidation
swift run WaypointKitDemo
```

Expected validation output:

```text
WaypointKit validation passed (50 validation cases).
```

## What To Try

- Run the CLI demo and confirm it proposes replacing `Shanghai Museum` with `Xuhui Riverside`.
- Inspect `Fixtures/route-edit-regressions.json` and `Fixtures/multi-turn-route-edits.json`.
- Add one small fixture case and wire it into `WaypointKitValidation`.
- Open `Examples/WaypointKitSwiftUIDemo` in Xcode as part of this package and render `WaypointKitDemoView()` inside an app shell.

## Good First Contributions

- Add a multi-turn fixture where the user answers a clarification question with a short reply.
- Add a proposal persistence example.
- Add provider adapter documentation for MapKit or an AMap-style provider without service keys.
- Improve docs where the route-state safety boundary is unclear.

Before opening a PR, run:

```bash
scripts/preflight.sh
```

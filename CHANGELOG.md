# Changelog

## Unreleased

- Added `WaypointKitDemo`, a no-network executable that demonstrates verified candidate replacement and reviewable route proposals.
- Added public route-editing regression fixtures and validation coverage for diff, narrative, usability, and warning behavior.
- Added evaluation documentation describing the fixture workflow and future regression surface.

## 0.1.1 - 2026-06-01

- Lowered the Swift tools version to 6.1 so GitHub Actions and common runner toolchains can validate the package.
- Added public maintenance-evidence documentation for the ETA-to-WaypointKit extraction boundary.
- Updated Codex for OSS application notes with public repository, release, issue, and pull request evidence.

## 0.1.0 - 2026-06-01

- Extracted WaypointKit as a standalone Swift package from ETA's route-planning core.
- Added waypoint models, route metrics, route diffing, favorites/search-history rules, coordinate conversion, AI intent routing, prompt builders, tool schemas, and proposal narratives.
- Added `WaypointKitValidation` with 39 framework-free validation cases.

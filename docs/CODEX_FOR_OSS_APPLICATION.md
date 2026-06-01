# Codex for Open Source Application Notes

Use this only after the GitHub repository is public and the first release exists.

## Project

Repository: `https://github.com/lycheeo/waypoint-kit`

Project name: `WaypointKit`

Role: primary maintainer

## Short Description

WaypointKit is an open-source Swift toolkit for AI-assisted route planning and waypoint editing. It helps apps turn natural-language itinerary changes into verified, reviewable waypoint proposals instead of letting a model directly invent coordinates or mutate route state.

## Why This Project Matters

AI travel and map experiences need a safer boundary between language understanding and real-world route state. WaypointKit provides that boundary:

- the model can classify intent and propose changes
- a POI provider verifies real places
- deterministic rules diff and validate the target route
- the app applies changes only after user confirmation

The project was extracted from ETA, a real iOS route-planning app developed and validated locally on device. This repository exposes the reusable core as a Swift package.

## Current Maintainer Evidence

- Swift package with public API and MIT license.
- Validation executable with 39 validation cases.
- Documentation for architecture, contribution flow, security, and roadmap.
- Initial release target: `v0.1.0`.

Fill these after publishing:

- Public repo URL:
- Release URL:
- Issues:
- Pull requests:
- Stars:
- Downloads:

## How Codex Would Help

Codex would be used for:

- reviewing PRs that change route-state behavior
- expanding validation coverage for multi-turn route edits
- maintaining prompt and schema regression fixtures
- improving provider abstractions for MapKit, AMap, and mock datasets
- keeping release notes and documentation synchronized with code changes

API credits would help run regression evaluations for:

- route-editing prompts
- POI disambiguation
- multi-turn itinerary updates
- failure cases where the model should ask a question instead of forcing an invalid route

## Application Draft

```text
I am the primary maintainer of WaypointKit, an open-source Swift toolkit for AI-assisted route planning and waypoint editing.

The project was extracted from ETA, a real iOS route-planning app I have been building and testing on device. WaypointKit focuses on a practical problem in AI travel software: LLMs can understand route changes, but they should not invent coordinates or directly mutate itinerary state. The package separates natural-language route editing from verified POI provider results, so route changes can be proposed, validated, diffed, tested, and safely applied.

The repository includes waypoint models, route metrics, route diffing, WGS-84 / GCJ-02 coordinate conversion, AI intent routing, OpenAI-compatible tool schemas, prompt builders, proposal narratives, documentation, and a validation executable covering the core behavior.

I plan to use Codex to review pull requests, expand validation coverage, improve provider abstractions, maintain release notes, and automate regression checks for route-editing prompts and schemas. API credits would help run evaluation workflows for route-editing quality, POI disambiguation, and multi-turn itinerary updates.
```

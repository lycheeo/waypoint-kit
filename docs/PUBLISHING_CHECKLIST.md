# Publishing Checklist

This repository is ready for public publishing after a GitHub repository is created.

## Before Publishing

- Run `scripts/preflight.sh`.
- Confirm no real API keys, device identifiers, Apple Team IDs, or private app-store configuration are present.
- Replace `lycheeo` in README and application notes after the remote repository exists.

## Create Remote Repository

Create a public GitHub repository named:

```text
waypoint-kit
```

Description:

```text
AI-assisted route planning and waypoint editing for Swift apps.
```

Recommended topics:

```text
swift, ios, route-planning, ai-agents, openai, mapkit, itinerary, swift-package
```

## Push

```bash
git remote add origin git@github.com:lycheeo/waypoint-kit.git
git push -u origin main
git tag -a v0.1.0 -m "WaypointKit 0.1.0"
git push origin v0.1.0
```

## Initial GitHub Issues

Create these public issues after pushing:

1. Add provider-neutral POI search protocol
2. Add mock POI provider fixtures for route-edit regressions
3. Add SwiftUI demo without committed service keys
4. Document WGS-84 / GCJ-02 provider boundaries with examples

## Initial Pull Requests

Use real branches for small follow-up work:

- `docs/provider-boundaries`: expand coordinate/provider documentation
- `validation/candidate-fixtures`: add more candidate scoring fixtures
- `example/swiftui-demo`: add a minimal demo app with mocked provider data

Merge them only after validation passes.

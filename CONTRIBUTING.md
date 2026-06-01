# Contributing

Contributions are welcome if they keep the package provider-neutral and testable.

## Local Validation

```bash
swift build
swift run WaypointKitValidation
```

## Guidelines

- Do not commit API keys, `.env` files, device identifiers, or app-store account material.
- Keep model-facing code separate from provider verification and route-state application.
- Prefer small PRs with focused validation coverage.
- Avoid adding UI framework dependencies to the `WaypointKit` library target.
- Keep provider examples optional and mockable.

## Good First Areas

- More route diff tests.
- More POI candidate scoring fixtures.
- Documentation examples for common app integrations.
- Provider-neutral interfaces for search and route calculation.

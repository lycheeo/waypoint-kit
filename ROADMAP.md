# Roadmap

## 0.1.x

- Keep the core model and route-editing rules stable.
- Add more provider-neutral POI candidate examples. Initial demo and route-edit fixtures are available in `WaypointKitDemo` and `Fixtures/`.
- Expand validation cases for multi-turn edits and candidate disambiguation.
- Publish a small SwiftUI demo that consumes the package without exposing service keys.

## 0.2.x

- Add a formal POI provider protocol and sample adapters.
- Expand prompt and schema regression fixtures beyond the initial route-edit fixtures.
- Add route proposal serialization examples for app persistence.
- Improve documentation for WGS-84 / GCJ-02 map-provider boundaries.

## Later

- Support richer itinerary constraints such as accessibility, weather, budget, and route pacing.
- Add benchmarks for large waypoint lists and frequent route edits.
- Explore provider adapters for MapKit, AMap, and mock local datasets.

# Roadmap

## 0.1.x

- Keep the core model and route-editing rules stable.
- Add more provider-neutral POI candidate examples. Initial demo and route-edit fixtures are available in `WaypointKitDemo` and `Fixtures/`.
- Expand validation cases for multi-turn edits and candidate disambiguation.
- Publish a small SwiftUI demo that consumes the package without exposing service keys. Initial build-checked example target is available in `Examples/`.

## 0.2.x

- Add a formal POI provider protocol and sample adapters. Initial `POIProvider` and `MockPOIProvider` are available.
- Expand prompt and schema regression fixtures beyond the initial route-edit fixtures.
- Add route proposal serialization examples for app persistence.
- Improve documentation for WGS-84 / GCJ-02 map-provider boundaries. Initial boundary documentation is available in `docs/COORDINATE_SYSTEMS.md`.

## 0.3.x

- Expand the SwiftUI example into a small app shell that demonstrates proposal review and apply/cancel states.
- Add provider adapter examples for MapKit and AMap without committed service keys.
- Add multi-turn route-edit regression fixtures and candidate disambiguation fixtures.

## Later

- Support richer itinerary constraints such as accessibility, weather, budget, and route pacing.
- Add benchmarks for large waypoint lists and frequent route edits.
- Explore provider adapters for MapKit, AMap, and mock local datasets.

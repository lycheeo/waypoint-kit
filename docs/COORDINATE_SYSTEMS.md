# Coordinate Systems

WaypointKit treats `Waypoint.latitude` and `Waypoint.longitude` as WGS-84 coordinates.

That default keeps the package portable across Apple platforms, GPS input, fixtures, and provider-neutral route editing. Provider adapters are responsible for converting coordinates at the boundary when a map service expects another system.

## Boundary Rule

| Layer | Coordinate system |
| --- | --- |
| `Waypoint` storage | WGS-84 |
| Validation fixtures | WGS-84 |
| SwiftUI demo and mock provider | WGS-84 |
| Apple MapKit input/output | WGS-84 |
| AMap provider request/response in mainland China | Convert at provider boundary when GCJ-02 is required |

The app should not store mixed coordinate systems in the same waypoint list.

## AMap Boundary

When an app calls an AMap-style provider that expects GCJ-02:

1. Convert the WGS-84 search center to GCJ-02 before the provider request.
2. Decode provider results according to the provider's documented coordinate system.
3. Convert provider results back to WGS-84 before constructing `Waypoint` values.
4. Keep route diffs, fixtures, proposal narratives, and app state in WGS-84.

WaypointKit exposes:

```swift
CoordinateConverter.wgs84ToGCJ02(_:)
CoordinateConverter.gcj02ToWGS84(_:)
CoordinateConverter.isInChina(longitude:latitude:)
```

`CoordinateConverter` returns the original coordinate outside mainland China bounds, so provider adapters can call it conditionally without shifting non-China routes.

## Provider Request Metadata

`POISearchRequest.centerCoordinateSystem` records which system the request center uses. The built-in `MockPOIProvider` keeps everything in WGS-84 and exists for tests, examples, and offline demos.

Real provider adapters should make the conversion explicit near the network boundary instead of hiding it in UI code or proposal application code.

## Review Checklist

- Do route state and fixtures remain WGS-84?
- Is provider-specific conversion isolated to a provider adapter?
- Are converted coordinates converted back before becoming `Waypoint` values?
- Are route diffs computed after provider verification, not from raw model output?

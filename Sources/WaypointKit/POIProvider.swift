import CoreLocation
import Foundation

public struct POISearchRequest: Sendable {
    public var query: String
    public var city: String?
    public var placeKind: String?
    public var center: CLLocationCoordinate2D?
    public var radiusMeters: Int?
    public var centerCoordinateSystem: RouteCoordinateSystem
    public var limit: Int?

    public init(
        query: String,
        city: String? = nil,
        placeKind: String? = nil,
        center: CLLocationCoordinate2D? = nil,
        radiusMeters: Int? = nil,
        centerCoordinateSystem: RouteCoordinateSystem = .wgs84,
        limit: Int? = nil
    ) {
        self.query = query
        self.city = city
        self.placeKind = placeKind
        self.center = center
        self.radiusMeters = radiusMeters
        self.centerCoordinateSystem = centerCoordinateSystem
        self.limit = limit
    }
}

public protocol POIProvider: Sendable {
    func searchPOIs(_ request: POISearchRequest) async throws -> [Waypoint]
}

public struct MockPOIProvider: POIProvider, Sendable {
    public var points: [Waypoint]

    public init(points: [Waypoint]) {
        self.points = points
    }

    public func searchPOIs(_ request: POISearchRequest) async throws -> [Waypoint] {
        let queryTokens = tokens(in: request.query)
        let city = normalized(request.city)
        let kind = normalized(request.placeKind)
        let matches = points.filter { point in
            matchesQuery(point, tokens: queryTokens) &&
                matchesCity(point, city: city) &&
                matchesPlaceKind(point, kind: kind)
        }

        guard let limit = request.limit else { return matches }
        return Array(matches.prefix(max(0, limit)))
    }

    private func matchesQuery(_ point: Waypoint, tokens: [String]) -> Bool {
        guard !tokens.isEmpty else { return true }
        let searchableText = text(for: point)
        return tokens.allSatisfy { searchableText.localizedCaseInsensitiveContains($0) }
    }

    private func matchesCity(_ point: Waypoint, city: String?) -> Bool {
        guard let city, !city.isEmpty else { return true }
        return [
            point.cityName,
            point.districtName,
            Optional(point.address)
        ]
        .compactMap { $0 }
        .contains { $0.localizedCaseInsensitiveContains(city) }
    }

    private func matchesPlaceKind(_ point: Waypoint, kind: String?) -> Bool {
        guard let kind, !kind.isEmpty else { return true }
        let searchableText = text(for: point)
        switch kind {
        case "food":
            return RouteListEditingPointRules.isFoodPoint(point) ||
                ["food", "restaurant", "dinner", "cafe"].contains { searchableText.localizedCaseInsensitiveContains($0) }
        case "indoor", "museum":
            return RouteListEditingPointRules.isIndoorPoint(point) ||
                ["indoor", "museum", "gallery"].contains { searchableText.localizedCaseInsensitiveContains($0) }
        case "scenic", "nature":
            return ["scenic", "park", "riverside", "river", "waterfront", "trail", "garden"].contains {
                searchableText.localizedCaseInsensitiveContains($0)
            }
        default:
            return searchableText.localizedCaseInsensitiveContains(kind)
        }
    }

    private func tokens(in query: String) -> [String] {
        query
            .split(whereSeparator: { $0.isWhitespace || $0.isNewline })
            .map(String.init)
            .filter { !$0.isEmpty }
    }

    private func normalized(_ value: String?) -> String? {
        let text = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return text.isEmpty ? nil : text
    }

    private func text(for point: Waypoint) -> String {
        [
            point.name,
            point.address,
            point.poiCategory,
            point.cityName,
            point.districtName,
            point.adcode
        ]
        .compactMap { $0 }
        .joined(separator: " ")
    }
}

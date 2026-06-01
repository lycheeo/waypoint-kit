import CoreLocation
import Foundation

public enum RouteTextFormatter {
    public static func shortDistance(kilometers: Double) -> String {
        if kilometers >= 100 {
            return "\(Int(kilometers.rounded())) km"
        }
        return String(format: "%.1f km", kilometers)
    }

    public static func shortDistance(meters: Double) -> String {
        shortDistance(kilometers: meters / 1000)
    }

    public static func shortMinutes(_ minutes: Int) -> String {
        guard minutes > 0 else { return "--" }
        if minutes < 60 { return "\(minutes) min" }
        let hours = minutes / 60
        let remainder = minutes % 60
        return remainder == 0 ? "\(hours) h" : "\(hours) h \(remainder) min"
    }
}

public extension Waypoint {
    static let placeIdentityCoordinateTolerance = 0.00001

    func isSamePlace(as other: Waypoint) -> Bool {
        abs(latitude - other.latitude) < Self.placeIdentityCoordinateTolerance &&
            abs(longitude - other.longitude) < Self.placeIdentityCoordinateTolerance
    }

    func coordinateDistance(to other: Waypoint) -> CLLocationDistance {
        CLLocation(latitude: latitude, longitude: longitude)
            .distance(from: CLLocation(latitude: other.latitude, longitude: other.longitude))
    }
}

public extension Sequence where Element == Waypoint {
    func deduplicatedByPlaceIdentity() -> [Waypoint] {
        reduce(into: [Waypoint]()) { result, point in
            guard !result.contains(where: { $0.isSamePlace(as: point) }) else { return }
            result.append(point)
        }
    }
}

public enum RouteMetrics {
    public static func totalStayMinutes(for points: [Waypoint]) -> Int {
        points.dropLast().reduce(0) { $0 + $1.stayMinutes }
    }

    public static func estimatedTravelMinutes(
        legs: [RouteLeg],
        routePoints: [Waypoint],
        transportMode: RouteTransportMode
    ) -> Int {
        let seconds = legs.reduce(0) { $0 + $1.travelTime }
        if seconds > 0 {
            return max(1, Int((seconds / 60).rounded()))
        }
        let km = routeDistanceKilometers(for: routePoints)
        guard km > 0 else { return 0 }
        return max(1, Int((km / transportMode.fallbackSpeedKmh * 60.0).rounded()))
    }

    public static func distanceText(legs: [RouteLeg], routePoints: [Waypoint]) -> String {
        let meters = legs.reduce(0) { $0 + $1.distanceMeters }
        let kilometers = meters > 0 ? meters / 1000 : routeDistanceKilometers(for: routePoints)
        return RouteTextFormatter.shortDistance(kilometers: kilometers)
    }

    public static func arrivalTimeText(
        estimatedTravelMinutes: Int,
        stayMinutes: Int,
        departureDate: Date = Date()
    ) -> String {
        let total = estimatedTravelMinutes + stayMinutes
        guard total > 0 else { return "--" }
        let date = Calendar.current.date(byAdding: .minute, value: total, to: departureDate) ?? departureDate
        return date.formatted(date: .omitted, time: .shortened)
    }

    public static func routeDistanceKilometers(for routePoints: [Waypoint]) -> Double {
        guard routePoints.count >= 2 else { return 0 }
        return zip(routePoints, routePoints.dropFirst()).reduce(0) { partial, pair in
            partial + pair.0.coordinateDistance(to: pair.1) / 1000.0
        }
    }
}

public enum RouteCollectionRules {
    public static let searchHistoryLimit = 12

    public static func searchHistory(remembering point: Waypoint, in history: [Waypoint]) -> [Waypoint] {
        var next = history
        next.removeAll {
            $0.name == point.name || $0.isSamePlace(as: point)
        }

        var copy = point
        copy.id = UUID()
        next.insert(copy, at: 0)

        if next.count > searchHistoryLimit {
            next = Array(next.prefix(searchHistoryLimit))
        }

        return next
    }

    public static func containsFavoritePlace(_ point: Waypoint, in places: [Waypoint]) -> Bool {
        places.contains { $0.isSamePlace(as: point) }
    }

    public static func toggledFavoritePlace(_ point: Waypoint, in places: [Waypoint]) -> [Waypoint] {
        var next = places
        if let index = next.firstIndex(where: { $0.isSamePlace(as: point) }) {
            next.remove(at: index)
        } else {
            next.insert(point, at: 0)
        }
        return next
    }

    public static func removedFavoritePlace(_ point: Waypoint, from places: [Waypoint]) -> [Waypoint] {
        places.filter { !$0.isSamePlace(as: point) }
    }

    public static func movedFavoritePlaceToTop(_ point: Waypoint, in places: [Waypoint]) -> [Waypoint] {
        guard let index = places.firstIndex(where: { $0.id == point.id }), index > 0 else { return places }
        var next = places
        let item = next.remove(at: index)
        next.insert(item, at: 0)
        return next
    }

    public static func toggledFavoritePlacePinned(_ point: Waypoint, in places: [Waypoint]) -> [Waypoint] {
        guard let index = places.firstIndex(where: { $0.id == point.id }) else { return places }
        var next = places
        var item = next.remove(at: index)
        item.isPinned = !(item.isPinned == true)
        let insertionIndex = item.isPinned == true ? 0 : firstUnpinnedPlaceIndex(in: next)
        next.insert(item, at: insertionIndex)
        return normalizedFavoritePlaces(next)
    }

    public static func movedFavoritePlace(_ point: Waypoint, direction: Int, in places: [Waypoint]) -> [Waypoint] {
        guard let index = places.firstIndex(where: { $0.id == point.id }) else { return places }
        let target = index + direction
        guard places.indices.contains(target) else { return places }
        var next = places
        next.swapAt(index, target)
        return normalizedFavoritePlaces(next)
    }

    public static func normalizedFavoritePlaces(_ places: [Waypoint]) -> [Waypoint] {
        places.stablePartitioned { $0.isPinned == true }
    }

    public static func movedFavoriteRouteToTop(_ route: FavoriteRoute, in routes: [FavoriteRoute]) -> [FavoriteRoute] {
        guard let index = routes.firstIndex(where: { $0.id == route.id }), index > 0 else { return routes }
        var next = routes
        let item = next.remove(at: index)
        next.insert(item, at: 0)
        return next
    }

    public static func toggledFavoriteRoutePinned(_ route: FavoriteRoute, in routes: [FavoriteRoute]) -> [FavoriteRoute] {
        guard let index = routes.firstIndex(where: { $0.id == route.id }) else { return routes }
        var next = routes
        var item = next.remove(at: index)
        item.isPinned = !(item.isPinned == true)
        let insertionIndex = item.isPinned == true ? 0 : firstUnpinnedRouteIndex(in: next)
        next.insert(item, at: insertionIndex)
        return normalizedFavoriteRoutes(next)
    }

    public static func movedFavoriteRoute(_ route: FavoriteRoute, direction: Int, in routes: [FavoriteRoute]) -> [FavoriteRoute] {
        guard let index = routes.firstIndex(where: { $0.id == route.id }) else { return routes }
        let target = index + direction
        guard routes.indices.contains(target) else { return routes }
        var next = routes
        next.swapAt(index, target)
        return normalizedFavoriteRoutes(next)
    }

    public static func normalizedFavoriteRoutes(_ routes: [FavoriteRoute]) -> [FavoriteRoute] {
        routes.stablePartitioned { $0.isPinned == true }
    }

    private static func firstUnpinnedPlaceIndex(in places: [Waypoint]) -> Int {
        places.firstIndex { $0.isPinned != true } ?? places.count
    }

    private static func firstUnpinnedRouteIndex(in routes: [FavoriteRoute]) -> Int {
        routes.firstIndex { $0.isPinned != true } ?? routes.count
    }
}

private extension Array {
    func stablePartitioned(_ belongsInFirstGroup: (Element) -> Bool) -> [Element] {
        filter(belongsInFirstGroup) + filter { !belongsInFirstGroup($0) }
    }
}

public enum RouteChangeDiffBuilder {
    public static func changes(before: [Waypoint], after: [Waypoint]) -> [RoutePointChange] {
        if before.map(signature) == after.map(signature) {
            return []
        }

        if before.count == after.count {
            let replacements = zip(before.enumerated(), after).compactMap { item -> RoutePointChange? in
                let index = item.0.offset
                let oldPoint = item.0.element
                let newPoint = item.1
                guard signature(for: oldPoint) != signature(for: newPoint) else { return nil }
                return RoutePointChange(
                    kind: .replaced,
                    beforeName: oldPoint.name,
                    afterName: newPoint.name,
                    detail: "stop \(index + 1)"
                )
            }

            let beforeSet = before.map(signature).sorted()
            let afterSet = after.map(signature).sorted()
            if beforeSet == afterSet {
                return [
                    RoutePointChange(
                        kind: .reordered,
                        beforeName: nil,
                        afterName: nil,
                        detail: "Waypoint order changed"
                    )
                ]
            }

            if !replacements.isEmpty {
                return replacements
            }
        }

        var remainingAfter = after
        let removed = before.compactMap { point -> RoutePointChange? in
            if let matchIndex = remainingAfter.firstIndex(where: { isSamePlace($0, point) }) {
                remainingAfter.remove(at: matchIndex)
                return nil
            }
            return RoutePointChange(
                kind: .removed,
                beforeName: point.name,
                afterName: nil,
                detail: point.address
            )
        }

        var remainingBefore = before
        let added = after.compactMap { point -> RoutePointChange? in
            if let matchIndex = remainingBefore.firstIndex(where: { isSamePlace($0, point) }) {
                remainingBefore.remove(at: matchIndex)
                return nil
            }
            return RoutePointChange(
                kind: .added,
                beforeName: nil,
                afterName: point.name,
                detail: point.address
            )
        }

        return removed + added
    }

    public static func warnings(for points: [Waypoint]) -> [RouteChangeWarning] {
        guard points.filter(\.isSelected).count < 2 else { return [] }
        return [
            RouteChangeWarning(
                severity: .blocking,
                title: "Not enough waypoints",
                detail: "At least two selected waypoints are required for a navigable route."
            )
        ]
    }

    private static func signature(for point: Waypoint) -> String {
        let lat = Int((point.latitude * 100_000).rounded())
        let lon = Int((point.longitude * 100_000).rounded())
        return "\(point.name)|\(point.address)|\(lat)|\(lon)"
    }

    private static func isSamePlace(_ lhs: Waypoint, _ rhs: Waypoint) -> Bool {
        if lhs.name == rhs.name,
           abs(lhs.latitude - rhs.latitude) < 0.0002,
           abs(lhs.longitude - rhs.longitude) < 0.0002 {
            return true
        }
        return signature(for: lhs) == signature(for: rhs)
    }
}

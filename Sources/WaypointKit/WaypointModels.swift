import CoreLocation
import Foundation

public struct Waypoint: Identifiable, Codable, Equatable {
    public var id: UUID
    public var name: String
    public var address: String
    public var latitude: Double
    public var longitude: Double
    public var isSelected: Bool
    public var stayMinutes: Int
    public var source: PlaceSource?
    public var poiCategory: String?
    public var cityName: String?
    public var districtName: String?
    public var adcode: String?
    public var distanceMetersFromCurrent: Double?
    public var isPinned: Bool?

    public init(
        id: UUID = UUID(),
        name: String,
        address: String,
        latitude: Double,
        longitude: Double,
        isSelected: Bool = true,
        stayMinutes: Int = 0,
        source: PlaceSource? = nil,
        poiCategory: String? = nil,
        cityName: String? = nil,
        districtName: String? = nil,
        adcode: String? = nil,
        distanceMetersFromCurrent: Double? = nil,
        isPinned: Bool? = nil
    ) {
        self.id = id
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.isSelected = isSelected
        self.stayMinutes = stayMinutes
        self.source = source
        self.poiCategory = poiCategory
        self.cityName = cityName
        self.districtName = districtName
        self.adcode = adcode
        self.distanceMetersFromCurrent = distanceMetersFromCurrent
        self.isPinned = isPinned
    }

    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

public typealias RoutePoint = Waypoint

public enum PlaceSource: String, Codable, Equatable {
    case amap = "AMap"
    case appleMaps = "Apple Maps"
    case gps = "GPS"
    case user = "User"
}

public enum RouteEngineSource: String, Equatable {
    case amap = "AMap route"
    case mapKit = "Apple route"
    case estimated = "Estimated route"
}

public enum RouteCoordinateSystem: String, Equatable, Codable {
    case wgs84
    case gcj02
}

public struct RouteCalculationResult {
    public var legs: [RouteLeg]
    public var source: RouteEngineSource
    public var didFallback: Bool

    public init(legs: [RouteLeg], source: RouteEngineSource, didFallback: Bool) {
        self.legs = legs
        self.source = source
        self.didFallback = didFallback
    }

    public var noticeText: String {
        didFallback ? "Fell back to \(source.rawValue)" : source.rawValue
    }
}

public enum RoutePolicy: String, CaseIterable, Codable, Identifiable {
    case recommended
    case highway
    case lowToll

    public var id: String { rawValue }
}

public enum RouteTransportMode: String, CaseIterable, Codable, Identifiable {
    case automobile
    case walking
    case cycling

    public var id: String { rawValue }

    public var fallbackSpeedKmh: Double {
        switch self {
        case .automobile: 30
        case .walking: 4.8
        case .cycling: 15
        }
    }
}

public struct FavoriteRoute: Identifiable, Codable, Equatable {
    public var id: UUID
    public var name: String
    public var points: [Waypoint]
    public var isPinned: Bool?

    public init(id: UUID = UUID(), name: String, points: [Waypoint], isPinned: Bool? = nil) {
        self.id = id
        self.name = name
        self.points = points
        self.isPinned = isPinned
    }
}

public struct RouteLeg: Identifiable {
    public var id: UUID
    public var fromID: UUID
    public var toID: UUID
    public var distanceMeters: CLLocationDistance
    public var travelTime: TimeInterval
    public var coordinates: [CLLocationCoordinate2D]
    public var coordinateSystem: RouteCoordinateSystem
    public var hasTolls: Bool
    public var tollAmount: Double
    public var trafficSegments: [RouteTrafficSegment]

    public init(
        id: UUID = UUID(),
        fromID: UUID,
        toID: UUID,
        distanceMeters: CLLocationDistance,
        travelTime: TimeInterval,
        coordinates: [CLLocationCoordinate2D] = [],
        coordinateSystem: RouteCoordinateSystem = .wgs84,
        hasTolls: Bool = false,
        tollAmount: Double = 0,
        trafficSegments: [RouteTrafficSegment] = []
    ) {
        self.id = id
        self.fromID = fromID
        self.toID = toID
        self.distanceMeters = distanceMeters
        self.travelTime = travelTime
        self.coordinates = coordinates
        self.coordinateSystem = coordinateSystem
        self.hasTolls = hasTolls
        self.tollAmount = tollAmount
        self.trafficSegments = trafficSegments
    }

    public var distanceText: String {
        RouteTextFormatter.shortDistance(meters: distanceMeters)
    }

    public var timeText: String {
        let minutes = max(1, Int((travelTime / 60).rounded()))
        return RouteTextFormatter.shortMinutes(minutes)
    }

    public var summaryText: String {
        "\(distanceText) · \(timeText)"
    }
}

public struct RouteTrafficSegment: Identifiable {
    public var id: UUID
    public var status: String
    public var coordinates: [CLLocationCoordinate2D]
    public var coordinateSystem: RouteCoordinateSystem

    public init(
        id: UUID = UUID(),
        status: String,
        coordinates: [CLLocationCoordinate2D],
        coordinateSystem: RouteCoordinateSystem = .wgs84
    ) {
        self.id = id
        self.status = status
        self.coordinates = coordinates
        self.coordinateSystem = coordinateSystem
    }
}

public enum RouteChangeSource: Equatable {
    case ai
    case generatedRouteReplace
    case generatedRouteAppend

    public var title: String {
        switch self {
        case .ai: "AI route proposal"
        case .generatedRouteReplace: "Replace current route"
        case .generatedRouteAppend: "Append to current route"
        }
    }
}

public enum RoutePointChangeKind: String, Equatable {
    case added
    case removed
    case replaced
    case reordered
}

public struct RoutePointChange: Identifiable, Equatable {
    public var id: UUID
    public var kind: RoutePointChangeKind
    public var beforeName: String?
    public var afterName: String?
    public var detail: String

    public init(
        id: UUID = UUID(),
        kind: RoutePointChangeKind,
        beforeName: String?,
        afterName: String?,
        detail: String
    ) {
        self.id = id
        self.kind = kind
        self.beforeName = beforeName
        self.afterName = afterName
        self.detail = detail
    }
}

public enum RouteChangeWarningSeverity: String, Equatable {
    case info
    case caution
    case blocking
}

public struct RouteChangeWarning: Identifiable, Equatable {
    public var id: UUID
    public var severity: RouteChangeWarningSeverity
    public var title: String
    public var detail: String

    public init(
        id: UUID = UUID(),
        severity: RouteChangeWarningSeverity,
        title: String,
        detail: String
    ) {
        self.id = id
        self.severity = severity
        self.title = title
        self.detail = detail
    }
}

public struct RouteChangeProposal: Identifiable, Equatable {
    public var id: UUID
    public var baseRouteVersion: Int
    public var createdAt: Date
    public var source: RouteChangeSource
    public var userPrompt: String
    public var beforePoints: [Waypoint]
    public var proposedPoints: [Waypoint]
    public var proposedRouteName: String?
    public var summary: String
    public var changes: [RoutePointChange]
    public var warnings: [RouteChangeWarning]

    public init(
        id: UUID = UUID(),
        baseRouteVersion: Int,
        createdAt: Date = Date(),
        source: RouteChangeSource,
        userPrompt: String,
        beforePoints: [Waypoint],
        proposedPoints: [Waypoint],
        proposedRouteName: String?,
        summary: String,
        changes: [RoutePointChange],
        warnings: [RouteChangeWarning]
    ) {
        self.id = id
        self.baseRouteVersion = baseRouteVersion
        self.createdAt = createdAt
        self.source = source
        self.userPrompt = userPrompt
        self.beforePoints = beforePoints
        self.proposedPoints = proposedPoints
        self.proposedRouteName = proposedRouteName
        self.summary = summary
        self.changes = changes
        self.warnings = warnings
    }

    public var isRouteUsable: Bool {
        proposedPoints.filter(\.isSelected).count >= 2
    }

    public var pointCountDeltaText: String {
        let delta = proposedPoints.count - beforePoints.count
        if delta > 0 { return "+\(delta) waypoints" }
        if delta < 0 { return "\(delta) waypoints" }
        return "same waypoint count"
    }

    public func isStale(currentRouteVersion: Int) -> Bool {
        baseRouteVersion != currentRouteVersion
    }
}

public enum RouteChangeApplyResult {
    case applied
    case stale
}

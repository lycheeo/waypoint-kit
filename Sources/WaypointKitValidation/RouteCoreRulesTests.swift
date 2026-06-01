import WaypointKit

struct RouteCoreRulesTests {
    func testTotalStayMinutesExcludesFinalDestination() {
        let points = [
            point("A", stayMinutes: 15),
            point("B", stayMinutes: 30),
            point("C", stayMinutes: 60)
        ]

        XCTAssertEqual(RouteMetrics.totalStayMinutes(for: points), 45)
    }
    func testEstimatedTravelMinutesPrefersCalculatedLegs() {
        let a = point("A")
        let b = point("B")
        let leg = RouteLeg(
            fromID: a.id,
            toID: b.id,
            distanceMeters: 12_300,
            travelTime: 1_800
        )

        XCTAssertEqual(
            RouteMetrics.estimatedTravelMinutes(legs: [leg], routePoints: [a, b], transportMode: .automobile),
            30
        )
    }
    func testEstimatedTravelMinutesFallsBackToPointDistance() {
        let minutes = RouteMetrics.estimatedTravelMinutes(
            legs: [],
            routePoints: [
                Waypoint(name: "A", address: "A", latitude: 31.2304, longitude: 121.4737),
                Waypoint(name: "B", address: "B", latitude: 31.2314, longitude: 121.4747)
            ],
            transportMode: .walking
        )

        XCTAssertEqual(minutes, 2)
    }
    func testDistanceTextUsesCalculatedLegsWhenAvailable() {
        let a = point("A")
        let b = point("B")
        let leg = RouteLeg(
            fromID: a.id,
            toID: b.id,
            distanceMeters: 12_300,
            travelTime: 1_800
        )

        XCTAssertEqual(RouteMetrics.distanceText(legs: [leg], routePoints: [a, b]), "12.3 km")
    }
    func testSamePlaceUsesCoordinateTolerance() {
        let base = Waypoint(name: "People's Square", address: "Shanghai", latitude: 31.2304, longitude: 121.4737)
        let nearby = Waypoint(name: "Different label", address: "Shanghai", latitude: 31.2304005, longitude: 121.4737005)

        XCTAssertTrue(base.isSamePlace(as: nearby))
    }
    func testDifferentPlaceOutsideCoordinateTolerance() {
        let base = Waypoint(name: "People's Square", address: "Shanghai", latitude: 31.2304, longitude: 121.4737)
        let different = Waypoint(name: "The Bund", address: "Shanghai", latitude: 31.2397, longitude: 121.4998)

        XCTAssertFalse(base.isSamePlace(as: different))
    }
    func testDeduplicationPreservesFirstMatchingPoint() {
        let base = Waypoint(name: "People's Square", address: "Shanghai", latitude: 31.2304, longitude: 121.4737)
        let duplicate = Waypoint(name: "People's Square Metro", address: "Shanghai", latitude: 31.2304005, longitude: 121.4737005)
        let other = Waypoint(name: "The Bund", address: "Shanghai", latitude: 31.2397, longitude: 121.4998)

        XCTAssertEqual([base, duplicate, other].deduplicatedByPlaceIdentity().map(\.name), ["People's Square", "The Bund"])
    }
    func testSearchHistoryMovesMatchingPlaceToFrontAndCapsLength() {
        let history = (0..<12).map { index in
            Waypoint(name: "History \(index)", address: "A", latitude: Double(index), longitude: Double(index))
        }
        let samePlace = Waypoint(name: "New name", address: "A", latitude: 3, longitude: 3)

        let next = RouteCollectionRules.searchHistory(remembering: samePlace, in: history)

        XCTAssertEqual(next.count, 12)
        XCTAssertEqual(next.first?.name, "New name")
        XCTAssertFalse(next.contains { $0.name == "History 3" })
        XCTAssertNotEqual(next.first?.id, samePlace.id)
    }
    func testToggleFavoritePlaceUsesPlaceIdentity() {
        let point = Waypoint(name: "A", address: "A", latitude: 22.0, longitude: 113.0)
        let places = [point, Waypoint(name: "B", address: "B", latitude: 23.0, longitude: 114.0)]

        let removed = RouteCollectionRules.toggledFavoritePlace(point, in: places)
        let inserted = RouteCollectionRules.toggledFavoritePlace(point, in: removed)

        XCTAssertEqual(removed.map(\.name), ["B"])
        XCTAssertEqual(inserted.map(\.name), ["A", "B"])
    }
    func testMovingFavoritePlaceCannotCrossPinnedBoundary() {
        var pinned = point("Pinned")
        pinned.isPinned = true
        let next = RouteCollectionRules.movedFavoritePlace(point("A"), direction: -1, in: [pinned, point("A"), point("B")])

        XCTAssertEqual(next.map(\.name), ["Pinned", "A", "B"])
    }
    func testTogglingFavoriteRoutePinnedKeepsPinnedRoutesFirst() {
        let routes = [
            FavoriteRoute(name: "A", points: []),
            FavoriteRoute(name: "B", points: []),
            FavoriteRoute(name: "C", points: [], isPinned: true)
        ]

        let pinned = RouteCollectionRules.toggledFavoriteRoutePinned(routes[1], in: routes)
        let unpinned = RouteCollectionRules.toggledFavoriteRoutePinned(pinned[0], in: pinned)

        XCTAssertEqual(pinned.map(\.name), ["B", "C", "A"])
        XCTAssertEqual(unpinned.map(\.name), ["C", "B", "A"])
    }
    func testWarningsBlockRoutesWithLessThanTwoSelectedPoints() {
        let warnings = RouteChangeDiffBuilder.warnings(for: [point("Only")])

        XCTAssertEqual(warnings.count, 1)
        XCTAssertEqual(warnings.first?.severity, .blocking)
    }
    func testReorderedSamePointsProduceSingleReorderChange() {
        let a = point("A")
        let b = point("B")

        let changes = RouteChangeDiffBuilder.changes(before: [a, b], after: [b, a])

        XCTAssertEqual(changes.count, 1)
        XCTAssertEqual(changes.first?.kind, .reordered)
    }
    func testChangedSameLengthRouteReportsReplacements() {
        let changes = RouteChangeDiffBuilder.changes(
            before: [point("A"), point("B")],
            after: [point("B"), point("C")]
        )

        XCTAssertEqual(changes.map(\.kind), [.replaced, .replaced])
        XCTAssertEqual(changes.first?.beforeName, "A")
        XCTAssertEqual(changes.first?.afterName, "B")
    }

    private func point(_ name: String, stayMinutes: Int = 0) -> Waypoint {
        Waypoint(name: name, address: name, latitude: 22.0, longitude: 113.0, stayMinutes: stayMinutes)
    }
}

import CoreLocation
import WaypointKit

struct POIProviderTests {
    func testMockProviderSearchesByQuery() async {
        let provider = MockPOIProvider(points: samplePoints)
        let results = try? await provider.searchPOIs(
            POISearchRequest(query: "Riverside", city: "Shanghai", limit: 5)
        )

        XCTAssertEqual(results?.map(\.name), ["Xuhui Riverside"])
    }

    func testMockProviderFiltersByCity() async {
        let provider = MockPOIProvider(points: samplePoints)
        let results = try? await provider.searchPOIs(
            POISearchRequest(query: "museum", city: "Shanghai")
        )

        XCTAssertEqual(results?.map(\.name), ["Shanghai Museum"])
    }

    func testMockProviderFiltersByPlaceKind() async {
        let provider = MockPOIProvider(points: samplePoints)
        let results = try? await provider.searchPOIs(
            POISearchRequest(query: "", city: "Shanghai", placeKind: "food")
        )

        XCTAssertEqual(results?.map(\.name), ["Yunnan Road Food Street"])
    }

    func testMockProviderKeepsRequestCoordinateBoundary() {
        let request = POISearchRequest(
            query: "riverside",
            center: CLLocationCoordinate2D(latitude: 31.2304, longitude: 121.4737),
            centerCoordinateSystem: .wgs84,
            limit: 1
        )

        XCTAssertEqual(request.centerCoordinateSystem, .wgs84)
        XCTAssertEqual(request.center?.latitude ?? 0, 31.2304, accuracy: 0.000001)
        XCTAssertEqual(request.limit, 1)
    }

    private var samplePoints: [Waypoint] {
        [
            Waypoint(
                name: "Xuhui Riverside",
                address: "Longteng Avenue, Shanghai",
                latitude: 31.1808,
                longitude: 121.4639,
                source: .user,
                poiCategory: "scenic riverside",
                cityName: "Shanghai",
                districtName: "Xuhui"
            ),
            Waypoint(
                name: "Yunnan Road Food Street",
                address: "Yunnan South Road, Shanghai",
                latitude: 31.2288,
                longitude: 121.4803,
                source: .user,
                poiCategory: "food restaurant",
                cityName: "Shanghai",
                districtName: "Huangpu"
            ),
            Waypoint(
                name: "Shanghai Museum",
                address: "201 Renmin Avenue, Shanghai",
                latitude: 31.2303,
                longitude: 121.4707,
                source: .user,
                poiCategory: "museum indoor",
                cityName: "Shanghai",
                districtName: "Huangpu"
            ),
            Waypoint(
                name: "Canton Tower",
                address: "Haizhu, Guangzhou",
                latitude: 23.1065,
                longitude: 113.3245,
                source: .user,
                poiCategory: "scenic landmark",
                cityName: "Guangzhou",
                districtName: "Haizhu"
            )
        ]
    }
}

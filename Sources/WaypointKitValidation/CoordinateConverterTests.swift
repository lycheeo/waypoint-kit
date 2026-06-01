import CoreLocation
import WaypointKit

struct CoordinateConverterTests {
    func testCoordinateOutsideChinaDoesNotConvert() {
        let sanFrancisco = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let converted = CoordinateConverter.wgs84ToGCJ02(sanFrancisco)

        XCTAssertEqual(converted.latitude, sanFrancisco.latitude, accuracy: 0.000001)
        XCTAssertEqual(converted.longitude, sanFrancisco.longitude, accuracy: 0.000001)
    }
    func testChinaBoundaryClassification() {
        XCTAssertTrue(CoordinateConverter.isInChina(longitude: 121.4737, latitude: 31.2304))
        XCTAssertFalse(CoordinateConverter.isInChina(longitude: -122.4194, latitude: 37.7749))
    }
    func testWGS84ToGCJ02AndBackStaysNearOriginalCoordinate() {
        let shanghai = CLLocationCoordinate2D(latitude: 31.2304, longitude: 121.4737)

        let gcj02 = CoordinateConverter.wgs84ToGCJ02(shanghai)
        let roundTrip = CoordinateConverter.gcj02ToWGS84(gcj02)

        XCTAssertEqual(roundTrip.latitude, shanghai.latitude, accuracy: 0.00002)
        XCTAssertEqual(roundTrip.longitude, shanghai.longitude, accuracy: 0.00002)
    }
}

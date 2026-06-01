import CoreLocation
import Foundation

public enum CoordinateConverter {
    private static let pi = Double.pi
    private static let a = 6378245.0
    private static let ee = 0.00669342162296594323

    public static func isInChina(longitude: Double, latitude: Double) -> Bool {
        longitude >= 72.004 && longitude <= 137.8347 &&
            latitude >= 0.8293 && latitude <= 55.8271
    }

    public static func wgs84ToGCJ02(_ coordinate: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        guard isInChina(longitude: coordinate.longitude, latitude: coordinate.latitude) else {
            return coordinate
        }

        var dLat = transformLatitude(
            x: coordinate.longitude - 105.0,
            y: coordinate.latitude - 35.0
        )
        var dLon = transformLongitude(
            x: coordinate.longitude - 105.0,
            y: coordinate.latitude - 35.0
        )
        let radLat = coordinate.latitude / 180.0 * pi
        var magic = sin(radLat)
        magic = 1 - ee * magic * magic
        let sqrtMagic = sqrt(magic)
        dLat = (dLat * 180.0) / ((a * (1 - ee)) / (magic * sqrtMagic) * pi)
        dLon = (dLon * 180.0) / (a / sqrtMagic * cos(radLat) * pi)
        return CLLocationCoordinate2D(
            latitude: coordinate.latitude + dLat,
            longitude: coordinate.longitude + dLon
        )
    }

    public static func gcj02ToWGS84(_ coordinate: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        guard isInChina(longitude: coordinate.longitude, latitude: coordinate.latitude) else {
            return coordinate
        }

        var wgsLatitude = coordinate.latitude
        var wgsLongitude = coordinate.longitude
        for _ in 0..<8 {
            let converted = wgs84ToGCJ02(
                CLLocationCoordinate2D(latitude: wgsLatitude, longitude: wgsLongitude)
            )
            wgsLatitude -= converted.latitude - coordinate.latitude
            wgsLongitude -= converted.longitude - coordinate.longitude
        }
        return CLLocationCoordinate2D(latitude: wgsLatitude, longitude: wgsLongitude)
    }

    private static func transformLatitude(x: Double, y: Double) -> Double {
        var ret = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + 0.2 * sqrt(abs(x))
        ret += (20.0 * sin(6.0 * x * pi) + 20.0 * sin(2.0 * x * pi)) * 2.0 / 3.0
        ret += (20.0 * sin(y * pi) + 40.0 * sin(y / 3.0 * pi)) * 2.0 / 3.0
        ret += (160.0 * sin(y / 12.0 * pi) + 320 * sin(y * pi / 30.0)) * 2.0 / 3.0
        return ret
    }

    private static func transformLongitude(x: Double, y: Double) -> Double {
        var ret = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * sqrt(abs(x))
        ret += (20.0 * sin(6.0 * x * pi) + 20.0 * sin(2.0 * x * pi)) * 2.0 / 3.0
        ret += (20.0 * sin(x * pi) + 40.0 * sin(x / 3.0 * pi)) * 2.0 / 3.0
        ret += (150.0 * sin(x / 12.0 * pi) + 300.0 * sin(x / 30.0 * pi)) * 2.0 / 3.0
        return ret
    }
}

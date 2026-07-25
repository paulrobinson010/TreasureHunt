import CoreLocation

enum GeoMath {
    static func distance(from a: CLLocationCoordinate2D, to b: CLLocationCoordinate2D) -> CLLocationDistance {
        CLLocation(latitude: a.latitude, longitude: a.longitude)
            .distance(from: CLLocation(latitude: b.latitude, longitude: b.longitude))
    }

    /// Initial bearing in degrees (0 = north, clockwise) from `a` to `b`.
    static func bearing(from a: CLLocationCoordinate2D, to b: CLLocationCoordinate2D) -> Double {
        let lat1 = a.latitude.radians
        let lat2 = b.latitude.radians
        let dLon = (b.longitude - a.longitude).radians
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        return (atan2(y, x).degrees + 360).truncatingRemainder(dividingBy: 360)
    }

    /// Moves a coordinate by `distance` metres along `bearing` degrees.
    static func offset(_ coordinate: CLLocationCoordinate2D, distance: Double, bearing: Double) -> CLLocationCoordinate2D {
        let earthRadius = 6_371_000.0
        let angular = distance / earthRadius
        let theta = bearing.radians
        let lat1 = coordinate.latitude.radians
        let lon1 = coordinate.longitude.radians
        let lat2 = asin(sin(lat1) * cos(angular) + cos(lat1) * sin(angular) * cos(theta))
        let lon2 = lon1 + atan2(sin(theta) * sin(angular) * cos(lat1), cos(angular) - sin(lat1) * sin(lat2))
        return CLLocationCoordinate2D(latitude: lat2.degrees, longitude: lon2.degrees)
    }

    /// Signed shortest rotation from angle `a` to angle `b`, in (-180, 180].
    static func angleDelta(_ a: Double, _ b: Double) -> Double {
        var d = (b - a).truncatingRemainder(dividingBy: 360)
        if d > 180 { d -= 360 }
        if d < -180 { d += 360 }
        return d
    }
}

private extension Double {
    var radians: Double { self * .pi / 180 }
    var degrees: Double { self * 180 / .pi }
}

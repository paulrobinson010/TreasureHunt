import MapKit

/// Locale-aware distance strings: metres for metric users, feet/miles where
/// that's the local convention. MKDistanceFormatter also applies sensible
/// coarse rounding for us.
enum DistanceText {
    private static let formatter: MKDistanceFormatter = {
        let formatter = MKDistanceFormatter()
        formatter.unitStyle = .abbreviated
        return formatter
    }()

    static func string(_ meters: CLLocationDistance) -> String {
        formatter.string(fromDistance: meters)
    }
}

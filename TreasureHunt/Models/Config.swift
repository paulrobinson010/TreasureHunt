import CoreLocation

/// Gameplay tuning knobs, all in one place.
enum Config {
    /// Radius of the fuzzy circle drawn on the hunt map for each unfound point.
    static let displayRadius: CLLocationDistance = 50

    /// Getting inside this distance of a point wakes the compass.
    static let zoneRadius: CLLocationDistance = 25

    /// Getting inside this distance counts as reaching the point (and starts
    /// the dig). Phone GPS is rarely better than ~3 m, so 1 m would be
    /// unwinnable in practice.
    static let foundRadius: CLLocationDistance = 3

    /// Hard ceiling on the dig trigger, however bad the GPS fix claims to be.
    static let maxDigRadius: CLLocationDistance = 8

    /// The dig trigger for a given fix. A phone reporting ±6 m can never
    /// report a distance under 3 m even standing on the treasure, so the
    /// threshold opens up to match the uncertainty — capped, so it stays a
    /// hunt rather than a stroll past.
    static func digRadius(accuracy: CLLocationAccuracy) -> CLLocationDistance {
        guard accuracy > 0 else { return foundRadius }
        return min(max(foundRadius, accuracy), maxDigRadius)
    }

    /// Degrees either side of the true bearing that count as "pointing at it".
    static let onTargetTolerance: Double = 20

    /// Radius of the rough area circle shown when previewing a hunt before starting it.
    static let previewRadius: CLLocationDistance = 150
}

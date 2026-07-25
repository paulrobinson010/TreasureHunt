import CoreLocation

/// Gameplay tuning knobs, all in one place.
enum Config {
    /// Radius of the fuzzy circle drawn on the hunt map for each unfound point.
    static let displayRadius: CLLocationDistance = 50

    /// Getting inside this distance of a point wakes the compass.
    static let zoneRadius: CLLocationDistance = 25

    /// Getting inside this distance counts as finding the point.
    /// Phone GPS is rarely better than ~3 m, so 1 m would be unwinnable in practice.
    static let foundRadius: CLLocationDistance = 3

    /// Degrees either side of the true bearing that count as "pointing at it".
    static let onTargetTolerance: Double = 20

    /// Radius of the rough area circle shown when previewing a hunt before starting it.
    static let previewRadius: CLLocationDistance = 150
}

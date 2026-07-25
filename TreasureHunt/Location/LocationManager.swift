import Combine
import CoreLocation

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var location: CLLocation?
    @Published var heading: CLHeading?
    @Published var authorization: CLAuthorizationStatus = .notDetermined

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.distanceFilter = kCLDistanceFilterNone
        manager.headingFilter = 2
    }

    /// Location only. Heading is opt-in via startHeading() — its updates fire
    /// on every couple of degrees of phone movement, and screens re-render on
    /// each one, so only the compass should subscribe.
    func start() {
        manager.requestWhenInUseAuthorization()
        beginUpdates()
    }

    func startHeading() {
        if CLLocationManager.headingAvailable() {
            manager.startUpdatingHeading()
        }
    }

    func stopHeading() {
        manager.stopUpdatingHeading()
    }

    func stop() {
        manager.stopUpdatingLocation()
        manager.stopUpdatingHeading()
    }

    /// Direction the phone is facing, in degrees. True north when available.
    var headingDegrees: Double? {
        guard let heading else { return nil }
        return heading.trueHeading >= 0 ? heading.trueHeading : heading.magneticHeading
    }

    private func beginUpdates() {
        manager.startUpdatingLocation()
    }

    // MARK: CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let new = locations.last else { return }
        // Throttle: GPS jitter delivers an update every second even standing
        // still, and each publish re-renders whole screens — which can cancel
        // an in-flight map gesture. Only publish real movement.
        if let old = location,
           new.distance(from: old) < 2,
           new.timestamp.timeIntervalSince(old.timestamp) < 5 {
            return
        }
        location = new
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        heading = newHeading
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorization = manager.authorizationStatus
        if authorization == .authorizedWhenInUse || authorization == .authorizedAlways {
            beginUpdates()
        }
    }
}

/// One-shot permission request for screens that show the user dot on a map
/// but don't need a stream of location updates (which would re-render the
/// screen and stutter map gestures).
enum LocationPermission {
    private static let manager = CLLocationManager()

    static func request() {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }
}

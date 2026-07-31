import MapKit
import SwiftUI

/// How the map behaves while hunting.
enum HuntMapMode: String, CaseIterable, Identifiable {
    /// Locked to the hunter, heading up: turn and the map turns.
    case free
    /// Same, plus a walking route drawn towards the target zone.
    case path
    /// Hands off: pan, zoom and look around wherever you like.
    case roam

    var id: String { rawValue }

    var label: String {
        switch self {
        case .free: "Free"
        case .path: "Path"
        case .roam: "Roam"
        }
    }

    var icon: String {
        switch self {
        case .free: "location.north.line.fill"
        case .path: "figure.walk"
        case .roam: "hand.draw.fill"
        }
    }

    var followsHunter: Bool { self != .roam }

    /// Follow modes keep zoom but drop panning — a stray drag used to knock
    /// the map out of follow, which is exactly what hunters don't want.
    var interactionModes: MapInteractionModes {
        followsHunter ? [.zoom] : .all
    }

    var cameraPosition: MapCameraPosition {
        followsHunter
            ? .userLocation(followsHeading: true, fallback: .automatic)
            : .userLocation(followsHeading: false, fallback: .automatic)
    }
}

/// Brand-styled three-way switch for the map modes.
struct MapModePicker: View {
    @Binding var mode: HuntMapMode

    var body: some View {
        HStack(spacing: 4) {
            ForEach(HuntMapMode.allCases) { option in
                Button {
                    mode = option
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: option.icon)
                            .font(.system(size: 12, weight: .semibold))
                        Text(option.label)
                            .font(.fun(13, .semibold))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(
                        mode == option ? Color.brandCyan : Color.clear,
                        in: Capsule()
                    )
                    .foregroundStyle(mode == option ? Color.brandNight : Color.brandCyan)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(.ultraThinMaterial, in: Capsule())
        .shadow(radius: 3)
    }
}

/// Fetches a walking route to the target zone for Path mode. Requests are
/// rate-limited: Apple throttles MKDirections, and the route only needs
/// refreshing when the target changes or the hunter has wandered.
@MainActor
final class WalkingRouteProvider: ObservableObject {
    @Published private(set) var route: MKPolyline?

    private var lastTargetID: UUID?
    private var lastOrigin: CLLocationCoordinate2D?
    private var lastRequest = Date.distantPast
    private var inFlight = false

    func clear() {
        route = nil
        lastTargetID = nil
        lastOrigin = nil
    }

    func update(from origin: CLLocationCoordinate2D, to point: TreasurePoint) {
        let targetChanged = lastTargetID != point.id
        let wandered = lastOrigin.map { GeoMath.distance(from: $0, to: origin) > 40 } ?? true
        let stale = Date().timeIntervalSince(lastRequest) > 45
        guard !inFlight, targetChanged || wandered || stale else { return }

        inFlight = true
        lastRequest = .now
        lastOrigin = origin
        lastTargetID = point.id

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: origin))
        // Route to the fuzzy centre, never the exact spot — the walk should
        // get hunters there without giving the treasure away.
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: point.displayCenter))
        request.transportType = .walking

        MKDirections(request: request).calculate { [weak self] response, _ in
            Task { @MainActor in
                guard let self else { return }
                self.inFlight = false
                if let first = response?.routes.first {
                    self.route = first.polyline
                }
            }
        }
    }
}

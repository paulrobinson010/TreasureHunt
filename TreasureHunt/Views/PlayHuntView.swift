import MapKit
import SwiftUI

/// The live hunt: fuzzy 50 m circles for unfound points, a compass that wakes
/// up inside 25 m, and success markers as points are found.
struct PlayHuntView: View {
    @EnvironmentObject private var store: HuntStore
    @StateObject private var locationManager = LocationManager()
    let huntID: UUID

    /// Heading-up follow: the way you're walking is up on the screen.
    @State private var camera: MapCameraPosition = .userLocation(followsHeading: true, fallback: .automatic)
    @State private var activePoint: TreasurePoint?
    @State private var showPrize = false
    @State private var trail: [CLLocationCoordinate2D] = []
    /// Current map rotation, so the guide arrow can point in screen space.
    @State private var cameraHeading: Double = 0
    @AppStorage("mapFlavor") private var mapFlavor: MapFlavor = .standard

    private var hunt: Hunt? { store.hunt(id: huntID) }

    var body: some View {
        Group {
            if let hunt {
                ZStack(alignment: .bottom) {
                    Map(position: $camera) {
                        UserAnnotation()
                        if trail.count > 1 {
                            // Dotted footsteps, like the trail on the island logo.
                            MapPolyline(coordinates: trail)
                                .stroke(Color.brandRed, style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [1, 10]))
                        }
                        ForEach(hunt.points) { point in
                            if hunt.isFound(point) {
                                Annotation("Found!", coordinate: point.coordinate) {
                                    LogoMarker(badge: .found, ring: .green)
                                }
                            } else {
                                MapCircle(center: point.displayCenter, radius: Config.displayRadius)
                                    .foregroundStyle(Color.brandCyan.opacity(0.3))
                            }
                        }
                    }
                    statusBar(for: hunt)
                }
                .mapStyle(mapFlavor.style)
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                }
                // Coarse threshold: the arrow only needs rough map rotation,
                // and per-frame state writes would stutter gestures.
                .onMapCameraChange(frequency: .continuous) { context in
                    if abs(GeoMath.angleDelta(cameraHeading, context.camera.heading)) > 3 {
                        cameraHeading = context.camera.heading
                    }
                }
                .overlay(alignment: .top) {
                    guidePointer(for: hunt)
                        .padding(.top, 8)
                }
                .overlay(alignment: .topTrailing) {
                    VStack(spacing: 8) {
                        MapStyleButton(flavor: $mapFlavor)
                        Button {
                            camera = .userLocation(followsHeading: true, fallback: .automatic)
                        } label: {
                            Image(systemName: "location.north.line.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Color.brandCyan)
                                .padding(10)
                                .background(.ultraThinMaterial, in: Circle())
                                .shadow(radius: 3)
                        }
                        .accessibilityLabel("Follow my walking direction")
                    }
                    .padding(8)
                }
                .overlay {
                    if let activePoint, !hunt.isFound(activePoint) {
                        CompassView(locationManager: locationManager, target: activePoint)
                    }
                }
            } else {
                ContentUnavailableView("Hunt not found", systemImage: "questionmark.circle")
            }
        }
        .navigationTitle(hunt?.name ?? "Hunt")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { locationManager.start() }
        .onDisappear {
            locationManager.stop()
            FeedbackManager.shared.stopBuzzing()
            FeedbackManager.shared.stopDetector()
        }
        .onChange(of: locationManager.location) { _, newLocation in
            update(with: newLocation)
        }
        .sheet(isPresented: $showPrize) {
            if let hunt {
                PrizeRevealView(hunt: hunt)
            }
        }
    }

    private func statusBar(for hunt: Hunt) -> some View {
        VStack(spacing: 6) {
            if locationManager.authorization == .denied {
                Text("Location access is off — turn it on in Settings to play")
                    .font(.fun(13))
                    .foregroundStyle(.red)
            }
            Text("\(hunt.foundPointIDs.count) of \(hunt.points.count) found")
                .font(.fun(17, .semibold))
            if hunt.isSolved {
                Button("Show my prize! 🎁") { showPrize = true }
                    .buttonStyle(.borderedProminent)
                    .tint(.brandRed)
            } else if let hint = hint(for: hunt) {
                Text(hint)
                    .font(.fun(13))
                    .foregroundStyle(.secondary)
            }
            if !hunt.foundPointIDs.isEmpty, let url = try? HuntShareCodec.progressURL(for: hunt) {
                ShareLink(item: progressMessage(for: hunt, url: url)) {
                    Label("Send progress to the hunt maker", systemImage: "paperplane.fill")
                        .font(.fun(13))
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
    }

    /// Floating arrow towards the nearest unfound zone (its fuzzy centre, so
    /// nothing exact leaks). Hidden once the compass takes over in a zone.
    @ViewBuilder
    private func guidePointer(for hunt: Hunt) -> some View {
        if !hunt.isSolved, activePoint == nil,
           let location = locationManager.location,
           let nearest = hunt.nearestUnfoundPoint(to: location.coordinate) {
            let bearing = GeoMath.bearing(from: location.coordinate, to: nearest.displayCenter)
            let distance = GeoMath.distance(from: location.coordinate, to: nearest.displayCenter)
            HStack(spacing: 8) {
                Image(systemName: "location.north.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.brandCyan)
                    .rotationEffect(.degrees(GeoMath.angleDelta(cameraHeading, bearing)))
                Text("~" + DistanceText.string((distance / 10).rounded() * 10))
                    .font(.fun(15, .semibold))
                    .monospacedDigit()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
            .shadow(radius: 3)
        }
    }

    private func progressMessage(for hunt: Hunt, url: URL) -> String {
        "🧭 \"\(hunt.name)\": I've found \(hunt.foundPointIDs.count) of \(hunt.points.count) treasures! Tap to update your map: \(url.absoluteString)"
    }

    private func hint(for hunt: Hunt) -> String? {
        guard let location = locationManager.location,
              let nearest = hunt.nearestUnfoundPoint(to: location.coordinate) else {
            return "Waiting for GPS…"
        }
        let distance = GeoMath.distance(from: location.coordinate, to: nearest.displayCenter)
        if distance <= Config.displayRadius {
            return "You're in the zone — keep moving to wake the compass"
        }
        // Rounded to ~10 m so the hint never becomes a rangefinder.
        return "Nearest treasure zone is about \(DistanceText.string((distance / 10).rounded() * 10)) away"
    }

    private func update(with location: CLLocation?) {
        guard let location else { return }
        recordTrail(location)
        guard let hunt, !hunt.isSolved,
              let nearest = hunt.nearestUnfoundPoint(to: location.coordinate) else { return }
        let distance = GeoMath.distance(from: location.coordinate, to: nearest.coordinate)

        if distance <= Config.foundRadius {
            found(nearest, in: hunt)
        } else if distance <= Config.zoneRadius {
            FeedbackManager.shared.updateDetector(distance: distance)
            if activePoint?.id != nearest.id {
                activePoint = nearest
            }
        } else {
            FeedbackManager.shared.stopDetector()
            if activePoint != nil {
                activePoint = nil
                FeedbackManager.shared.stopBuzzing()
            }
        }
    }

    /// Every few metres of walking becomes a dot on the trail.
    private func recordTrail(_ location: CLLocation) {
        if let last = trail.last {
            guard GeoMath.distance(from: last, to: location.coordinate) > 4 else { return }
        }
        trail.append(location.coordinate)
        if trail.count > 2000 {
            trail.removeFirst(trail.count - 2000)
        }
    }

    private func found(_ point: TreasurePoint, in hunt: Hunt) {
        FeedbackManager.shared.stopBuzzing()
        FeedbackManager.shared.stopDetector()
        activePoint = nil
        store.markFound(point, in: hunt)
        if store.hunt(id: huntID)?.isSolved == true {
            FeedbackManager.shared.solvedFanfare()
            showPrize = true
        } else {
            FeedbackManager.shared.pointFanfare()
        }
    }
}

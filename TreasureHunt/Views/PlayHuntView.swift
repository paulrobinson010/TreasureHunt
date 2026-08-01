import MapKit
import SwiftUI

/// The live hunt: fuzzy 50 m circles for unfound points, a compass that wakes
/// up inside 25 m, and success markers as points are found.
struct PlayHuntView: View {
    @EnvironmentObject private var store: HuntStore
    @StateObject private var locationManager = LocationManager()
    @StateObject private var routeProvider = WalkingRouteProvider()
    let huntID: UUID

    @State private var camera: MapCameraPosition = HuntMapMode.free.cameraPosition
    @State private var activePoint: TreasurePoint?
    @State private var showPrize = false
    @State private var trail: [CLLocationCoordinate2D] = []
    /// Set when the hunter reaches an X: the dig begins.
    @State private var digPoint: TreasurePoint?
    @State private var digLoot: LootItem?
    /// Current map rotation, so the guide arrow can point in screen space.
    @State private var cameraHeading: Double = 0
    @AppStorage("mapFlavor") private var mapFlavor: MapFlavor = .standard
    @AppStorage("huntMapMode") private var mapMode: HuntMapMode = .free

    private var hunt: Hunt? { store.hunt(id: huntID) }

    var body: some View {
        Group {
            if let hunt {
                ZStack(alignment: .bottom) {
                    // Equatable child: location ticks re-render the overlays
                    // below, but never the map itself — re-rendering a map
                    // mid-gesture cancels the gesture.
                    HuntMap(
                        hunt: hunt,
                        trail: trail,
                        flavor: mapFlavor,
                        mode: mapMode,
                        route: mapMode == .path ? routeProvider.route : nil,
                        camera: $camera
                    )
                    .equatable()
                    statusBar(for: hunt)
                }
                // Coarse threshold: the arrow only needs rough map rotation,
                // and per-frame state writes would stutter gestures.
                .onMapCameraChange(frequency: .continuous) { context in
                    if abs(GeoMath.angleDelta(cameraHeading, context.camera.heading)) > 3 {
                        cameraHeading = context.camera.heading
                    }
                }
                .overlay(alignment: .top) {
                    VStack(spacing: 8) {
                        MapModePicker(mode: $mapMode)
                        guidePointer(for: hunt)
                    }
                    .padding(.top, 8)
                }
                .overlay(alignment: .topTrailing) {
                    VStack(spacing: 8) {
                        MapStyleButton(flavor: $mapFlavor)
                        Button {
                            recentre()
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
                    if let activePoint, digPoint == nil, !hunt.isFound(activePoint) {
                        CompassView(locationManager: locationManager, target: activePoint)
                    }
                }
                .overlay {
                    if let digPoint, let digLoot {
                        DigView(loot: digLoot) {
                            store.collect(digLoot)
                            found(digPoint, in: hunt)
                            self.digPoint = nil
                            self.digLoot = nil
                        }
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
        .onChange(of: mapMode) { _, newMode in
            camera = newMode.cameraPosition
            if newMode == .path {
                updateRoute()
            } else {
                routeProvider.clear()
            }
        }
        .sheet(isPresented: $showPrize) {
            if let hunt {
                PrizeRevealView(hunt: hunt)
            }
        }
    }

    private func recentre() {
        camera = mapMode.followsHunter
            ? mapMode.cameraPosition
            : .userLocation(followsHeading: false, fallback: .automatic)
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
           let nearest = hunt.targetPoint(from: location.coordinate) {
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

    private func hint(for hunt: Hunt) -> String? {
        guard let location = locationManager.location,
              let nearest = hunt.targetPoint(from: location.coordinate) else {
            return "Waiting for GPS…"
        }
        let distance = GeoMath.distance(from: location.coordinate, to: nearest.displayCenter)
        if distance <= Config.displayRadius {
            return "You're in the zone — keep moving to wake the compass"
        }
        // Rounded to ~10 m so the hint never becomes a rangefinder.
        let label = hunt.sequential ? "The next treasure zone" : "Nearest treasure zone"
        return "\(label) is about \(DistanceText.string((distance / 10).rounded() * 10)) away"
    }

    private func updateRoute() {
        guard mapMode == .path,
              let location = locationManager.location,
              let hunt, !hunt.isSolved,
              let target = hunt.targetPoint(from: location.coordinate) else { return }
        routeProvider.update(from: location.coordinate, to: target)
    }

    private func update(with location: CLLocation?) {
        guard let location else { return }
        recordTrail(location)
        updateRoute()
        guard let hunt, !hunt.isSolved,
              let nearest = hunt.targetPoint(from: location.coordinate) else { return }
        let distance = GeoMath.distance(from: location.coordinate, to: nearest.coordinate)

        if distance <= Config.digRadius(accuracy: location.horizontalAccuracy) {
            // Reached the X — time to dig, not to auto-find.
            guard digPoint == nil else { return }
            FeedbackManager.shared.stopDetector()
            FeedbackManager.shared.stopBuzzing()
            activePoint = nil
            digLoot = LootCatalog.roll(huntName: hunt.name)
            digPoint = nearest
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

    /// The map and only the map: skipped by SwiftUI unless something it
    /// actually shows has changed.
    private struct HuntMap: View, Equatable {
        let hunt: Hunt
        let trail: [CLLocationCoordinate2D]
        let flavor: MapFlavor
        let mode: HuntMapMode
        let route: MKPolyline?
        @Binding var camera: MapCameraPosition

        static func == (a: Self, b: Self) -> Bool {
            a.hunt.id == b.hunt.id
                && a.hunt.foundPointIDs == b.hunt.foundPointIDs
                && a.trail.count == b.trail.count
                && a.flavor == b.flavor
                && a.mode == b.mode
                && a.route === b.route
        }

        var body: some View {
            Map(position: $camera, interactionModes: mode.interactionModes) {
                UserAnnotation()
                if let route {
                    MapPolyline(route)
                        .stroke(Color.brandLime, style: StrokeStyle(lineWidth: 7, lineCap: .round, lineJoin: .round))
                }
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
                    } else if !hunt.sequential || point.id == hunt.unfoundPoints.first?.id {
                        // Sequential hunts reveal one zone at a time.
                        // Solid bright edge: outdoors, in sunlight, a soft
                        // wash of colour is easy to miss.
                        MapCircle(center: point.displayCenter, radius: Config.displayRadius)
                            .foregroundStyle(Color.brandCyan.opacity(0.22))
                            .stroke(Color.brandCyan, lineWidth: 5)
                    }
                }
            }
            .mapStyle(flavor.style)
            .mapControls {
                MapUserLocationButton()
                MapCompass()
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
        routeProvider.clear()
        updateRoute()
    }
}

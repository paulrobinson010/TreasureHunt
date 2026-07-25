import MapKit
import SwiftUI

/// The live hunt: fuzzy 50 m circles for unfound points, a compass that wakes
/// up inside 25 m, and success markers as points are found.
struct PlayHuntView: View {
    @EnvironmentObject private var store: HuntStore
    @StateObject private var locationManager = LocationManager()
    let huntID: UUID

    @State private var camera: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var activePoint: TreasurePoint?
    @State private var showPrize = false

    private var hunt: Hunt? { store.hunt(id: huntID) }

    var body: some View {
        Group {
            if let hunt {
                ZStack(alignment: .bottom) {
                    Map(position: $camera) {
                        UserAnnotation()
                        ForEach(hunt.points) { point in
                            if hunt.isFound(point) {
                                Annotation("Found!", coordinate: point.coordinate) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title)
                                        .foregroundStyle(.white, .green)
                                }
                            } else {
                                MapCircle(center: point.displayCenter, radius: Config.displayRadius)
                                    .foregroundStyle(.orange.opacity(0.3))
                            }
                        }
                    }
                    statusBar(for: hunt)
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
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
            Text("\(hunt.foundPointIDs.count) of \(hunt.points.count) found")
                .font(.headline)
            if hunt.isSolved {
                Button("Show my prize! 🎁") { showPrize = true }
                    .buttonStyle(.borderedProminent)
            } else if let hint = hint(for: hunt) {
                Text(hint)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
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
        // Rounded to 10 m so the hint never becomes a rangefinder.
        return String(format: "Nearest treasure zone is about %.0f m away", (distance / 10).rounded() * 10)
    }

    private func update(with location: CLLocation?) {
        guard let location, let hunt, !hunt.isSolved,
              let nearest = hunt.nearestUnfoundPoint(to: location.coordinate) else { return }
        let distance = GeoMath.distance(from: location.coordinate, to: nearest.coordinate)

        if distance <= Config.foundRadius {
            found(nearest, in: hunt)
        } else if distance <= Config.zoneRadius {
            if activePoint?.id != nearest.id {
                activePoint = nearest
                FeedbackManager.shared.ping()
            }
        } else if activePoint != nil {
            activePoint = nil
            FeedbackManager.shared.stopBuzzing()
        }
    }

    private func found(_ point: TreasurePoint, in hunt: Hunt) {
        FeedbackManager.shared.stopBuzzing()
        FeedbackManager.shared.success()
        activePoint = nil
        store.markFound(point, in: hunt)
        if store.hunt(id: huntID)?.isSolved == true {
            showPrize = true
        }
    }
}

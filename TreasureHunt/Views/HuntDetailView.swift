import MapKit
import SwiftUI

/// Routes a hunt to the right screen for its role and state.
struct HuntDetailView: View {
    @EnvironmentObject private var store: HuntStore
    let huntID: UUID

    var body: some View {
        if let hunt = store.hunt(id: huntID) {
            switch hunt.role {
            case .created:
                CreatedHuntView(hunt: hunt)
            case .received:
                if hunt.isSolved {
                    ScrollView { PrizeRevealView(hunt: hunt) }
                        .background(OceanBackground())
                } else {
                    HuntPreviewView(hunt: hunt)
                }
            }
        } else {
            ContentUnavailableView("Hunt not found", systemImage: "questionmark.circle")
        }
    }
}

/// The maker's view: exact points, prize, and re-share.
struct CreatedHuntView: View {
    let hunt: Hunt
    @State private var sharing = false
    @AppStorage("mapFlavor") private var mapFlavor: MapFlavor = .standard

    var body: some View {
        VStack(spacing: 0) {
            Map(initialPosition: .region(hunt.pointsRegion)) {
                UserAnnotation()
                ForEach(Array(hunt.points.enumerated()), id: \.element.id) { index, point in
                    Marker(
                        hunt.isFound(point) ? "Found!" : "Point \(index + 1)",
                        systemImage: hunt.isFound(point) ? "checkmark" : "mappin",
                        coordinate: point.coordinate
                    )
                    .tint(hunt.isFound(point) ? .green : Color.brandRed)
                }
            }
            .mapStyle(mapFlavor.style)
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            .overlay(alignment: .topTrailing) {
                MapStyleButton(flavor: $mapFlavor)
                    .padding(8)
            }
            List {
                Section("Hunters' progress") {
                    huntersProgress
                }
                .listRowBackground(Color.brandCard)
                Section("Prize") {
                    Text(hunt.prize.isEmpty ? "No prize written down" : hunt.prize)
                }
                .listRowBackground(Color.brandCard)
                Section {
                    Button {
                        sharing = true
                    } label: {
                        Label("Share this hunt", systemImage: "square.and.arrow.up")
                    }
                }
                .listRowBackground(Color.brandCard)
            }
            .scrollContentBackground(.hidden)
            .background(OceanBackground())
            .frame(height: 300)
        }
        .navigationTitle(hunt.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $sharing) {
            ShareHuntView(hunt: hunt)
        }
    }

    @ViewBuilder
    private var huntersProgress: some View {
        if hunt.foundPointIDs.isEmpty {
            Text("Nothing found yet. When a hunter taps \"Send progress\" in their app, this map updates.")
                .font(.fun(13))
                .foregroundStyle(.secondary)
        } else {
            Text(hunt.isSolved
                 ? "Solved — all \(hunt.points.count) treasures found! 🎉"
                 : "\(hunt.foundPointIDs.count) of \(hunt.points.count) treasures found")
            if let updated = hunt.progressUpdatedAt {
                Text("Last update \(updated.formatted(date: .abbreviated, time: .shortened))")
                    .font(.fun(12))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private extension Hunt {
    /// A settled region comfortably containing every point — .automatic keeps
    /// re-framing content and fights the user's gestures.
    var pointsRegion: MKCoordinateRegion {
        let coords = points.map(\.coordinate)
        guard let first = coords.first else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                latitudinalMeters: 1000, longitudinalMeters: 1000
            )
        }
        var minLat = first.latitude, maxLat = first.latitude
        var minLon = first.longitude, maxLon = first.longitude
        for c in coords {
            minLat = min(minLat, c.latitude); maxLat = max(maxLat, c.latitude)
            minLon = min(minLon, c.longitude); maxLon = max(maxLon, c.longitude)
        }
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2),
            span: MKCoordinateSpan(
                latitudeDelta: max((maxLat - minLat) * 1.5, 0.005),
                longitudeDelta: max((maxLon - minLon) * 1.5, 0.005)
            )
        )
    }
}

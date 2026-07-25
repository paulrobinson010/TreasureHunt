import MapKit
import SwiftUI

/// Pre-hunt preview: shows only a rough area near the closest point — enough to
/// know where to go, not enough to spoil the hunt.
struct HuntPreviewView: View {
    let hunt: Hunt
    @StateObject private var locationManager = LocationManager()
    @State private var started = false
    @AppStorage("mapFlavor") private var mapFlavor: MapFlavor = .standard

    var body: some View {
        Group {
            if started {
                PlayHuntView(huntID: hunt.id)
            } else {
                preview
            }
        }
    }

    private var preview: some View {
        VStack(spacing: 0) {
            Map(initialPosition: .automatic) {
                UserAnnotation()
                if let center = previewCenter {
                    MapCircle(center: center, radius: Config.previewRadius)
                        .foregroundStyle(Color.brandCyan.opacity(0.25))
                }
            }
            .mapStyle(mapFlavor.style)
            .overlay(alignment: .topTrailing) {
                MapStyleButton(flavor: $mapFlavor)
                    .padding(8)
            }
            VStack(spacing: 12) {
                Text(hunt.name)
                    .font(.fun(24, .bold))
                Text("\(hunt.points.count) treasure point\(hunt.points.count == 1 ? "" : "s") to find")
                    .foregroundStyle(.secondary)
                Label("The prize is revealed when you find every point", systemImage: "gift")
                    .font(.fun(13))
                    .foregroundStyle(.secondary)
                Button {
                    started = true
                } label: {
                    Text(hunt.foundPointIDs.isEmpty
                         ? "Start the hunt"
                         : "Keep hunting (\(hunt.foundPointIDs.count)/\(hunt.points.count) found)")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(OceanBackground())
        }
        .navigationTitle("Preview")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { locationManager.start() }
        .onDisappear { locationManager.stop() }
    }

    /// Blurred centre near whichever point is closest to the hunter right now.
    private var previewCenter: CLLocationCoordinate2D? {
        guard !hunt.points.isEmpty else { return nil }
        let target: TreasurePoint
        if let location = locationManager.location {
            target = hunt.points.min {
                GeoMath.distance(from: location.coordinate, to: $0.coordinate)
                    < GeoMath.distance(from: location.coordinate, to: $1.coordinate)
            } ?? hunt.points[0]
        } else {
            target = hunt.points[0]
        }
        return target.previewCenter
    }
}

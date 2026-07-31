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
            Map(initialPosition: previewCamera) {
                UserAnnotation()
                if let center = previewCenter {
                    MapCircle(center: center, radius: Config.previewRadius)
                        .foregroundStyle(Color.brandCyan.opacity(0.25))
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
            VStack(spacing: 12) {
                Text(hunt.name)
                    .font(.fun(24, .bold))
                Text("\(hunt.points.count) treasure point\(hunt.points.count == 1 ? "" : "s") to find\(hunt.sequential ? " — in order!" : "")")
                    .foregroundStyle(.secondary)
                Label("The prize is revealed when you find every point", systemImage: "gift")
                    .font(.fun(13))
                    .foregroundStyle(.secondary)
                // A scheduled hunt can be held and looked at, but not started
                // until its moment arrives — so the wait is part of the fun.
                TimelineView(.periodic(from: .now, by: 1)) { _ in
                    if hunt.hasFinished {
                        VStack(spacing: 6) {
                            Text("This hunt has finished")
                                .font(.fun(17, .semibold))
                                .foregroundStyle(Color.brandSand)
                            Text("The treasure has been packed away. Ask for a new hunt!")
                                .font(.fun(13))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.brandCard, in: RoundedRectangle(cornerRadius: 18))
                    } else if let startsAt = hunt.startsAt, startsAt > .now {
                        VStack(spacing: 6) {
                            Text("Starts \(startsAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(.fun(15, .semibold))
                                .foregroundStyle(Color.brandSand)
                            Text(countdown(to: startsAt))
                                .font(.fun(30, .bold))
                                .monospacedDigit()
                                .foregroundStyle(Color.brandCyan)
                            Text("Get your boots on! 🥾")
                                .font(.fun(13))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.brandCard, in: RoundedRectangle(cornerRadius: 18))
                    } else {
                        Button {
                            started = true
                        } label: {
                            Text(hunt.foundPointIDs.isEmpty
                                 ? "Start the hunt!"
                                 : "Keep hunting (\(hunt.foundPointIDs.count)/\(hunt.points.count) found)")
                                .font(.fun(18, .bold))
                                .foregroundStyle(Color.brandNight)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    LinearGradient(colors: [.brandCyan, .brandLime],
                                                   startPoint: .leading, endPoint: .trailing),
                                    in: Capsule()
                                )
                        }
                    }
                }
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

    /// "2 days 4 hrs" far out, "04:31" when it's nearly time.
    private func countdown(to date: Date) -> String {
        let seconds = max(0, Int(date.timeIntervalSinceNow))
        let days = seconds / 86400
        let hours = (seconds % 86400) / 3600
        let minutes = (seconds % 3600) / 60
        if days > 0 { return "\(days) day\(days == 1 ? "" : "s") \(hours) hr\(hours == 1 ? "" : "s")" }
        if hours > 0 { return String(format: "%d:%02d:%02d", hours, minutes, seconds % 60) }
        return String(format: "%02d:%02d", minutes, seconds % 60)
    }

    /// A settled region around the rough area — .automatic keeps re-framing
    /// content and makes gestures clunky.
    private var previewCamera: MapCameraPosition {
        guard let center = previewCenter else {
            return .userLocation(fallback: .automatic)
        }
        return .region(MKCoordinateRegion(
            center: center,
            latitudinalMeters: Config.previewRadius * 6,
            longitudinalMeters: Config.previewRadius * 6
        ))
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

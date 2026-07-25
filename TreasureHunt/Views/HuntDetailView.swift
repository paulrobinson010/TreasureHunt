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

    var body: some View {
        VStack(spacing: 0) {
            Map(initialPosition: .automatic) {
                ForEach(Array(hunt.points.enumerated()), id: \.element.id) { index, point in
                    Marker(
                        hunt.isFound(point) ? "Found!" : "Point \(index + 1)",
                        systemImage: hunt.isFound(point) ? "checkmark" : "mappin",
                        coordinate: point.coordinate
                    )
                    .tint(hunt.isFound(point) ? .green : Color.brandRed)
                }
            }
            List {
                Section("Hunters' progress") {
                    if hunt.foundPointIDs.isEmpty {
                        Text("Nothing found yet. When the kids tap \"Send progress\" in their app, this map updates.")
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
                Section("Prize") {
                    Text(hunt.prize.isEmpty ? "No prize written down" : hunt.prize)
                }
                Section {
                    Button {
                        sharing = true
                    } label: {
                        Label("Share with the kids", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .frame(height: 300)
        }
        .navigationTitle(hunt.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $sharing) {
            ShareHuntView(hunt: hunt)
        }
    }
}

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
                    Marker("Point \(index + 1)", coordinate: point.coordinate)
                }
            }
            List {
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
            .frame(height: 230)
        }
        .navigationTitle(hunt.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $sharing) {
            ShareHuntView(hunt: hunt)
        }
    }
}

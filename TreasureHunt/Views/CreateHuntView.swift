import MapKit
import SwiftUI

struct CreateHuntView: View {
    @EnvironmentObject private var store: HuntStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationManager = LocationManager()

    @State private var name = ""
    @State private var prize = ""
    @State private var points: [TreasurePoint] = []
    @State private var camera: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var sharing: Hunt?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                MapReader { proxy in
                    Map(position: $camera) {
                        UserAnnotation()
                        ForEach(Array(points.enumerated()), id: \.element.id) { index, point in
                            Annotation("Point \(index + 1)", coordinate: point.coordinate) {
                                Image(systemName: "\(min(index + 1, 50)).circle.fill")
                                    .font(.title)
                                    .foregroundStyle(.white, Color.brandRed)
                            }
                        }
                    }
                    .onTapGesture { position in
                        if let coordinate = proxy.convert(position, from: .local) {
                            points.append(TreasurePoint(coordinate: coordinate))
                        }
                    }
                }
                .overlay(alignment: .top) {
                    Text(points.isEmpty
                         ? "Tap the map to drop your first treasure point"
                         : "\(points.count) point\(points.count == 1 ? "" : "s") placed — tap to add more")
                        .font(.fun(13))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.top, 8)
                }

                Form {
                    Section("Details") {
                        TextField("Hunt name", text: $name)
                        TextField("Prize (revealed when solved)", text: $prize, axis: .vertical)
                    }
                    Section {
                        Button("Remove last point", role: .destructive) {
                            _ = points.popLast()
                        }
                        .disabled(points.isEmpty)
                    }
                }
                .frame(height: 240)
            }
            .navigationTitle("New Hunt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(points.isEmpty || name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { locationManager.start() }
            .onDisappear { locationManager.stop() }
            .sheet(item: $sharing, onDismiss: { dismiss() }) { hunt in
                ShareHuntView(hunt: hunt)
            }
        }
    }

    private func save() {
        let hunt = Hunt(
            id: UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            prize: prize.trimmingCharacters(in: .whitespacesAndNewlines),
            points: points,
            role: .created,
            createdAt: .now
        )
        store.add(hunt)
        sharing = hunt
    }
}

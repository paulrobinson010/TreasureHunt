import CryptoKit
import MapKit
import SwiftUI

struct CreateHuntView: View {
    @EnvironmentObject private var store: HuntStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var prize = ""
    @State private var points: [TreasurePoint] = []
    @State private var sequential = false
    @State private var scheduled = false
    @State private var startsAt = Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
    @State private var sharing: Hunt?

    private enum Field { case name, prize }
    @FocusState private var focusedField: Field?
    /// The map centre lives in a plain box, NOT @State: publishing it after a
    /// gesture re-renders the view at the exact moment the next drag starts
    /// and swallows it. It's only ever read when the drop button is tapped.
    private final class CenterBox {
        var coordinate: CLLocationCoordinate2D?
    }
    @State private var centerBox = CenterBox()
    @AppStorage("mapFlavor") private var mapFlavor: MapFlavor = .standard

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Map(initialPosition: .userLocation(fallback: .automatic)) {
                    UserAnnotation()
                    ForEach(Array(points.enumerated()), id: \.element.id) { index, point in
                        Annotation("Point \(index + 1)", coordinate: point.coordinate) {
                            LogoMarker(badge: .number(index + 1))
                        }
                    }
                }
                .mapStyle(mapFlavor.style)
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                }
                // Continuous is free now — writing the box never re-renders.
                .onMapCameraChange(frequency: .continuous) { context in
                    centerBox.coordinate = context.camera.centerCoordinate
                }
                .overlay(alignment: .topTrailing) {
                    MapStyleButton(flavor: $mapFlavor)
                        .padding(8)
                }
                .overlay {
                    // The X — the map moves under it, so there's no tap
                    // gesture to fight MapKit's pan/zoom.
                    Image(systemName: "plus")
                        .font(.system(size: 34, weight: .heavy))
                        .rotationEffect(.degrees(45))
                        .foregroundStyle(Color.brandRed)
                        .shadow(color: .black.opacity(0.5), radius: 2)
                        .allowsHitTesting(false)
                }
                .overlay(alignment: .bottom) {
                    Button {
                        focusedField = nil
                        addPointAtX()
                    } label: {
                        Label("Drop point on the X", systemImage: "mappin.and.ellipse")
                            .font(.fun(15, .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(Color.brandRed, in: Capsule())
                            .shadow(radius: 4)
                    }
                    .padding(.bottom, 12)
                }
                .overlay(alignment: .top) {
                    Text(points.isEmpty
                         ? "Line up the X and tap \"Drop point on the X\""
                         : "\(points.count) point\(points.count == 1 ? "" : "s") placed — move the map to add more")
                        .font(.fun(13))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.top, 8)
                }

                Form {
                    Section("Details") {
                        TextField("Hunt name", text: $name)
                            .focused($focusedField, equals: .name)
                        TextField("Prize (revealed when the hunt is complete)", text: $prize, axis: .vertical)
                            .focused($focusedField, equals: .prize)
                        Toggle("Find points in order (1, 2, 3…)", isOn: $sequential)
                        Toggle("Starts at a set time", isOn: $scheduled)
                        if scheduled {
                            DatePicker("Hunt begins", selection: $startsAt, in: Date.now...)
                                .font(.fun(15))
                        }
                    }
                    .listRowBackground(Color.brandCard)
                    Section {
                        Button("Remove last point", role: .destructive) {
                            _ = points.popLast()
                        }
                        .disabled(points.isEmpty)
                    }
                    .listRowBackground(Color.brandCard)
                }
                .scrollContentBackground(.hidden)
                .background(OceanBackground())
                .scrollDismissesKeyboard(.interactively)
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
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                }
            }
            .onAppear { LocationPermission.request() }
            .sheet(item: $sharing, onDismiss: { dismiss() }) { hunt in
                ShareHuntView(hunt: hunt)
            }
        }
    }

    private func addPointAtX() {
        guard let center = centerBox.coordinate else { return }
        points.append(TreasurePoint(coordinate: center))
    }

    private func save() {
        let syncKey = SymmetricKey(size: .bits128).withUnsafeBytes { Data($0) }
        let hunt = Hunt(
            id: UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            prize: prize.trimmingCharacters(in: .whitespacesAndNewlines),
            points: points,
            role: .created,
            createdAt: .now,
            syncToken: ProgressSync.makeToken(),
            syncKeyData: syncKey,
            sequential: sequential,
            startsAt: scheduled ? startsAt : nil
        )
        store.add(hunt)
        sharing = hunt
    }
}

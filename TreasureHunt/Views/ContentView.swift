import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: HuntStore
    @State private var creating = false
    @State private var importing = false
    @State private var importText = ""
    @State private var importFailed = false

    private var toSolve: [Hunt] { store.hunts.filter { $0.role == .received && !$0.isSolved } }
    private var solved: [Hunt] { store.hunts.filter { $0.role == .received && $0.isSolved } }
    private var mine: [Hunt] { store.hunts.filter { $0.role == .created } }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Image("BrandLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 170)
                        .frame(maxWidth: .infinity)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                if store.hunts.isEmpty {
                    VStack(spacing: 10) {
                        Text("🏴‍☠️")
                            .font(.system(size: 56))
                        Text("No treasure hunts yet!")
                            .font(.fun(22, .bold))
                            .foregroundStyle(Color.brandSand)
                        Text("Make a hunt with + and send it to your hunters, or import one that was sent to you.")
                            .font(.fun(14))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
                huntSection("Hunts to solve", emoji: "🧭", color: .brandCyan, hunts: toSolve)
                huntSection("Solved", emoji: "🏆", color: .brandSand, hunts: solved)
                huntSection("Made by me", emoji: "🗺️", color: .brandLime, hunts: mine)
            }
            .scrollContentBackground(.hidden)
            .background(OceanBackground())
            .navigationTitle("X-Marks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Title stays empty — the big logo header below carries the brand.
                ToolbarItem(placement: .principal) {
                    Color.clear.frame(width: 1, height: 1)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        importing = true
                    } label: {
                        Label("Import", systemImage: "square.and.arrow.down")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        creating = true
                    } label: {
                        Label("New hunt", systemImage: "plus")
                    }
                }
            }
            .fullScreenCover(isPresented: $creating) {
                CreateHuntView()
            }
            .alert("Import a hunt", isPresented: $importing) {
                TextField("Paste the link here", text: $importText)
                Button("Import") { runImport() }
                Button("Cancel", role: .cancel) { importText = "" }
            } message: {
                Text("Paste a treasure hunt link that was sent to you.")
            }
            .alert("That didn't look like a treasure hunt link.", isPresented: $importFailed) {
                Button("OK") {}
            }
        }
    }

    @ViewBuilder
    private func huntSection(_ title: String, emoji: String, color: Color, hunts: [Hunt]) -> some View {
        if !hunts.isEmpty {
            Section {
                ForEach(hunts) { hunt in
                    NavigationLink {
                        HuntDetailView(huntID: hunt.id)
                    } label: {
                        HuntRow(hunt: hunt)
                    }
                    .swipeActions {
                        Button("Delete", role: .destructive) {
                            store.delete(hunt)
                        }
                    }
                    .listRowBackground(Color.brandCard)
                }
            } header: {
                HStack(spacing: 6) {
                    Text(emoji)
                    Text(title)
                        .font(.fun(15, .bold))
                        .foregroundStyle(color)
                }
                .textCase(nil)
            }
        }
    }

    private func runImport() {
        let text = importText.trimmingCharacters(in: .whitespacesAndNewlines)
        importText = ""
        var decoded: HuntShareCodec.Decoded?
        // The link is usually buried in a longer message — fish it out.
        if let range = text.range(of: "https://[^\\s]+", options: .regularExpression),
           let url = URL(string: String(text[range])) {
            decoded = HuntShareCodec.decode(url: url)
        } else if let range = text.range(of: "treasurehunt://[A-Za-z0-9_\\-/]+", options: .regularExpression),
                  let url = URL(string: String(text[range])) {
            decoded = HuntShareCodec.decode(url: url)
        } else if let hunt = HuntShareCodec.hunt(fromCode: text) {
            decoded = .hunt(hunt)
        }
        switch decoded {
        case .hunt(let hunt):
            store.importHunt(hunt)
        case .progress(let report):
            if store.applyProgress(report) == nil { importFailed = true }
        case nil:
            importFailed = true
        }
    }
}

struct HuntRow: View {
    let hunt: Hunt

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.22))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(hunt.name)
                    .font(.fun(17, .semibold))
                Text(subtitle)
                    .font(.fun(12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                if hunt.points.count <= 12 {
                    HStack(spacing: 4) {
                        ForEach(Array(hunt.points.enumerated()), id: \.element.id) { index, point in
                            Circle()
                                .fill(hunt.isFound(point)
                                      ? Color.candy[index % Color.candy.count]
                                      : Color.white.opacity(0.15))
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.top, 1)
                }
            }
        }
    }

    private var icon: String {
        if hunt.role == .created { return "paperplane.circle.fill" }
        return hunt.isSolved ? "trophy.fill" : "map.fill"
    }

    private var color: Color {
        if hunt.role == .created { return .brandCyan }
        return hunt.isSolved ? .brandSand : .brandLime
    }

    private var subtitle: String {
        let total = hunt.points.count
        switch hunt.role {
        case .created:
            return "\(total) point\(total == 1 ? "" : "s") · prize: \(hunt.prize.isEmpty ? "none" : hunt.prize)"
        case .received:
            if hunt.isSolved { return "Solved! All \(total) found" }
            return "\(hunt.foundPointIDs.count) of \(total) points found"
        }
    }
}

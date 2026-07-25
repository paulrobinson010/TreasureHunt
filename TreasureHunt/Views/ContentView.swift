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
                if store.hunts.isEmpty {
                    ContentUnavailableView {
                        Label("No treasure hunts yet", systemImage: "map")
                    } description: {
                        Text("Make a hunt with + and send it to the kids, or import one that was sent to you.")
                    }
                }
                huntSection("Hunts to solve", hunts: toSolve)
                huntSection("Solved", hunts: solved)
                huntSection("Made by me", hunts: mine)
            }
            .navigationTitle("Treasure Hunt")
            .toolbar {
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
            .sheet(isPresented: $creating) {
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
    private func huntSection(_ title: String, hunts: [Hunt]) -> some View {
        if !hunts.isEmpty {
            Section(title) {
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
                }
            }
        }
    }

    private func runImport() {
        let text = importText.trimmingCharacters(in: .whitespacesAndNewlines)
        importText = ""
        var hunt: Hunt?
        // The link is usually buried in a longer message — fish it out.
        if let range = text.range(of: "https://[^\\s]+", options: .regularExpression),
           let url = URL(string: String(text[range])) {
            hunt = HuntShareCodec.hunt(fromURL: url)
        } else if let range = text.range(of: "treasurehunt://[A-Za-z0-9_\\-/]+", options: .regularExpression),
                  let url = URL(string: String(text[range])) {
            hunt = HuntShareCodec.hunt(fromURL: url)
        } else {
            hunt = HuntShareCodec.hunt(fromCode: text)
        }
        if let hunt {
            store.importHunt(hunt)
        } else {
            importFailed = true
        }
    }
}

struct HuntRow: View {
    let hunt: Hunt

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(hunt.name)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }

    private var icon: String {
        if hunt.role == .created { return "paperplane.circle.fill" }
        return hunt.isSolved ? "trophy.fill" : "map.fill"
    }

    private var color: Color {
        if hunt.role == .created { return .blue }
        return hunt.isSolved ? .yellow : .orange
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

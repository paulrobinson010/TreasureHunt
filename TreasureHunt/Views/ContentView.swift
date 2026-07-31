import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: HuntStore
    @EnvironmentObject private var crew: CrewStore
    @EnvironmentObject private var gate: ParentGate
    @Environment(\.scenePhase) private var scenePhase
    @State private var creating = false
    @State private var showingCrew = false
    @State private var importing = false
    @State private var importText = ""
    @State private var importFailed = false
    @State private var importResult: ImportResult?
    /// A hunt from someone not yet in the crew, waiting on a grown-up.
    @State private var invite: HuntInvite?

    struct HuntInvite: Identifiable {
        let hunt: Hunt
        let sender: CrewCard?
        var id: UUID { hunt.id }
    }

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
                huntSection("Complete", emoji: "🏆", color: .brandSand, hunts: solved)
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
                #if targetEnvironment(simulator)
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        store.loadDemoData()
                    } label: {
                        Label("Demo", systemImage: "wand.and.stars")
                    }
                }
                #endif
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        importing = true
                    } label: {
                        Label("Import", systemImage: "square.and.arrow.down")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        gate.guarding { showingCrew = true }
                    } label: {
                        Image(systemName: "person.2.fill")
                    }
                    .accessibilityLabel("My crew")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        TreasureChestView()
                    } label: {
                        Text("💰")
                    }
                    .accessibilityLabel("My treasure chest")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        gate.guarding { creating = true }
                    } label: {
                        Label("New hunt", systemImage: "plus")
                    }
                }
            }
            .fullScreenCover(isPresented: $creating) {
                CreateHuntView()
            }
            .navigationDestination(isPresented: $showingCrew) {
                CrewView()
            }
            .parentGate(gate)
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
            .alert(
                "X-Marks",
                isPresented: Binding(
                    get: { importResult != nil },
                    set: { if !$0 { importResult = nil } }
                ),
                presenting: importResult
            ) { _ in
                Button("OK") {}
            } message: { result in
                Text(result.message)
            }
            .sheet(item: $invite) { invite in
                HuntInviteView(
                    hunt: invite.hunt,
                    sender: invite.sender,
                    onAccept: { accept(invite) },
                    onDecline: { self.invite = nil }
                )
            }
            .onOpenURL { handle(url: $0) }
            .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                if let url = activity.webpageURL { handle(url: url) }
            }
            .task { refreshCreatedHunts() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { refreshCreatedHunts() }
                // Phone handed back to a child shouldn't still be unlocked.
                if phase == .background { gate.lock() }
            }
        }
    }

    /// Pull hunters' automatic updates for every hunt made on this phone, so
    /// progress dots light up from the home screen — not only inside a hunt.
    private func refreshCreatedHunts() {
        for hunt in store.hunts where hunt.role == .created && hunt.syncToken != nil {
            ProgressSync.fetch(hunt: hunt) { found in
                if let found {
                    store.applyRemoteProgress(huntID: hunt.id, foundPointIDs: found)
                }
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
        } else if let range = text.range(of: "treasurehunt://[^\\s]+", options: .regularExpression),
                  let url = URL(string: String(text[range])) {
            decoded = HuntShareCodec.decode(url: url)
        } else if let found = HuntShareCodec.huntAndSender(fromCode: text) {
            decoded = .hunt(found.0, sender: found.1)
        }
        guard let decoded else {
            importFailed = true
            return
        }
        apply(decoded)
    }

    private func handle(url: URL) {
        guard let decoded = HuntShareCodec.decode(url: url) else {
            importResult = .failed
            return
        }
        apply(decoded)
    }

    /// Hunts from a crewmate land straight in the list. Anyone else has to
    /// get past a grown-up first — and saying yes adds them to the crew, so
    /// it only ever happens once per sender.
    private func apply(_ decoded: HuntShareCodec.Decoded) {
        switch decoded {
        case .hunt(let hunt, let sender):
            if store.hunt(id: hunt.id) != nil {
                importResult = .duplicate(hunt.name)
            } else if let sender, crew.contains(publicKey: sender.publicKey) {
                store.importHunt(hunt)
                importResult = .imported(hunt.name, from: "\(sender.name) ✓")
            } else {
                invite = HuntInvite(hunt: hunt, sender: sender)
            }
        case .crewInvite(let card):
            gate.guarding {
                let isNew = crew.add(card)
                importResult = .crewJoined(card.name, isNew: isNew)
            }
        case .progress(let report):
            if let updated = store.applyProgress(report) {
                importResult = .progress(updated.name, updated.foundPointIDs.count, updated.points.count)
            } else {
                importResult = .progressUnknown(report.name)
            }
        }
    }

    private func accept(_ invite: HuntInvite) {
        if let sender = invite.sender {
            crew.add(sender)
        }
        store.importHunt(invite.hunt)
        importResult = .imported(invite.hunt.name, from: invite.sender?.name)
        self.invite = nil
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
            if hunt.isSolved { return "Complete! All \(total) found" }
            if let startsAt = hunt.startsAt, startsAt > .now {
                return "Starts \(startsAt.formatted(date: .abbreviated, time: .shortened))"
            }
            return "\(hunt.foundPointIDs.count) of \(total) points found"
        }
    }
}

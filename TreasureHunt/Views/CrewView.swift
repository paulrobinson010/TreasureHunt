import SwiftUI

/// Who can send you treasure hunts — and the handshake that adds them.
struct CrewView: View {
    @EnvironmentObject private var crew: CrewStore
    @Environment(\.dismiss) private var dismiss
    @State private var myName = HunterIdentity.name
    @State private var inviteURL: URL?
    @State private var role = DeviceSetup.role ?? .grownUp
    @State private var confirmRoleChange = false

    var body: some View {
        List {
            Section("This phone") {
                HStack(spacing: 10) {
                    Text(role == .grownUp ? "🧭" : "🏴‍☠️")
                        .font(.system(size: 26))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(role == .grownUp ? "A grown-up's phone" : "A young hunter's phone")
                            .font(.fun(16, .semibold))
                        Text(role == .grownUp
                             ? "Can make hunts and choose the crew."
                             : "Hunting only. Hunts arrive from the crew, and nobody else.")
                            .font(.fun(12))
                            .foregroundStyle(.secondary)
                    }
                }
                Button(role == .grownUp ? "Make this a hunter's phone" : "Make this a grown-up's phone") {
                    confirmRoleChange = true
                }
                .font(.fun(14))
            }
            .listRowBackground(Color.brandCard)

            Section("My hunting name") {
                TextField("What should hunters call you?", text: $myName)
                    .onSubmit { HunterIdentity.name = myName }
                    .onChange(of: myName) { _, new in HunterIdentity.name = new }
                Text("This is the name shown when you send someone a hunt.")
                    .font(.fun(12))
                    .foregroundStyle(.secondary)
            }
            .listRowBackground(Color.brandCard)

            Section("Add someone early") {
                if let inviteURL {
                    ShareLink(item: inviteMessage(inviteURL)) {
                        Label("Send my hunting card", systemImage: "person.badge.plus")
                    }
                }
                Text("Optional — sending a hunt does this by itself. Your first hunt asks a grown-up on their phone to accept, and that adds you to their crew.")
                    .font(.fun(12))
                    .foregroundStyle(.secondary)
            }
            .listRowBackground(Color.brandCard)

            Section("Who can send me hunts") {
                if crew.members.isEmpty {
                    Text("Nobody yet. Hunts from anyone else need a grown-up to accept them first.")
                        .font(.fun(12))
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(crew.members) { member in
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(Color.brandLime.opacity(0.22))
                                    .frame(width: 34, height: 34)
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(Color.brandLime)
                            }
                            Text(member.name)
                                .font(.fun(16, .semibold))
                        }
                        .swipeActions {
                            Button("Remove", role: .destructive) {
                                crew.remove(member)
                            }
                        }
                    }
                }
            }
            .listRowBackground(Color.brandCard)
        }
        .scrollContentBackground(.hidden)
        .background(OceanBackground())
        .navigationTitle("My Crew")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { inviteURL = try? HuntShareCodec.crewInviteURL() }
        .alert("Change this phone?", isPresented: $confirmRoleChange) {
            Button("Change", role: .destructive) { changeRole() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(role == .grownUp
                 ? "This phone will only be able to go hunting. You'll set a grown-up passcode to change it back."
                 : "This phone will be able to make hunts and change the crew. Only do this on your own phone.")
        }
    }

    private func changeRole() {
        if role == .grownUp {
            // Handing the phone to a hunter: run setup again so a passcode
            // gets set. Clearing the role is what triggers it.
            DeviceSetup.reset()
        } else {
            // Only reachable past the passcode gate that opened this screen.
            DeviceSetup.setRole(.grownUp)
            DeviceSetup.clearPasscode()
            role = .grownUp
        }
        dismiss()
    }

    private func inviteMessage(_ url: URL) -> String {
        "🏴‍☠️ \(HunterIdentity.name) wants to swap treasure hunts with you on X-Marks! Tap to add them: \(url.absoluteString)"
    }
}

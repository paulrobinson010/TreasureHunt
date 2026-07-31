import SwiftUI

/// Who can send you treasure hunts — and the handshake that adds them.
struct CrewView: View {
    @EnvironmentObject private var crew: CrewStore
    @State private var myName = HunterIdentity.name
    @State private var inviteURL: URL?

    var body: some View {
        List {
            Section("My hunting name") {
                TextField("What should hunters call you?", text: $myName)
                    .onSubmit { HunterIdentity.name = myName }
                    .onChange(of: myName) { _, new in HunterIdentity.name = new }
                Text("This is the name shown when you send someone a hunt.")
                    .font(.fun(12))
                    .foregroundStyle(.secondary)
            }
            .listRowBackground(Color.brandCard)

            Section("Join up with someone") {
                if let inviteURL {
                    ShareLink(item: inviteMessage(inviteURL)) {
                        Label("Send my hunting card", systemImage: "person.badge.plus")
                    }
                }
                Text("Send your card, and ask them to send theirs back. Once you've both tapped each other's card, you're crewmates — hunts between you arrive marked as trusted.")
                    .font(.fun(12))
                    .foregroundStyle(.secondary)
            }
            .listRowBackground(Color.brandCard)

            Section("My crew") {
                if crew.members.isEmpty {
                    Text("Nobody yet. Anyone can still send you a hunt by link — crewmates just arrive with a tick so you know who they're from.")
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
    }

    private func inviteMessage(_ url: URL) -> String {
        "🏴‍☠️ \(HunterIdentity.name) wants to swap treasure hunts with you on X-Marks! Tap to add them: \(url.absoluteString)"
    }
}

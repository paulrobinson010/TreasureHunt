import SwiftUI

/// A hunt has arrived from someone this phone doesn't know yet. A grown-up
/// decides — and accepting adds the sender to the crew, so their next hunt
/// comes straight through.
struct HuntInviteView: View {
    let hunt: Hunt
    let sender: CrewCard?
    var onAccept: () -> Void
    var onDecline: () -> Void

    /// Its own gate: accepting a hunt from a new sender deserves its own
    /// check, and sharing one instance would have two screens racing to
    /// present the same sheet.
    @StateObject private var gate = ParentGate()
    @EnvironmentObject private var crew: CrewStore

    /// A stranger can call themselves anything, including the name of someone
    /// already trusted. The signature will verify — as a *different* key — so
    /// the collision has to be shouted about rather than glossed over.
    private var impersonates: CrewCard? {
        guard let sender else { return nil }
        return crew.members.first {
            $0.name.caseInsensitiveCompare(sender.name) == .orderedSame
                && $0.publicKey != sender.publicKey
        }
    }

    private var senderName: String { sender?.name ?? "Someone" }

    var body: some View {
        VStack(spacing: 16) {
            Image("BrandLogo")
                .resizable()
                .scaledToFit()
                .frame(height: 100)

            Text("\(senderName) has sent you a treasure hunt!")
                .font(.fun(21, .bold))
                .foregroundStyle(Color.brandSand)
                .multilineTextAlignment(.center)

            VStack(spacing: 4) {
                Text("\"\(hunt.name)\"")
                    .font(.fun(18, .semibold))
                Text("\(hunt.points.count) treasure point\(hunt.points.count == 1 ? "" : "s")")
                    .font(.fun(14))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.brandCard, in: RoundedRectangle(cornerRadius: 18))

            if impersonates != nil {
                Label(
                    "STOP — you already have a different \(senderName) in your crew, and this is NOT them. Anyone can put any name on a hunt. Unless you are certain who sent this, say no thanks.",
                    systemImage: "exclamationmark.triangle.fill"
                )
                .font(.fun(14, .semibold))
                .foregroundStyle(Color.brandRed)
                .padding(12)
                .background(Color.brandRed.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
            } else {
                Label(
                    sender == nil
                        ? "This hunt doesn't say who it's from. Only accept hunts from someone you know."
                        : "\(senderName) isn't in your crew yet. Accepting adds them, so their hunts arrive straight away from now on. Names aren't checked by anyone — only accept if you know who this is.",
                    systemImage: "person.badge.shield.checkmark"
                )
                .font(.fun(13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
            }

            Button {
                gate.guarding { onAccept() }
            } label: {
                Text("Ask a grown-up to accept")
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

            Button("No thanks", role: .destructive) { onDecline() }
                .font(.fun(15))
        }
        .padding(26)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(OceanBackground())
        .parentGate(gate)
    }
}

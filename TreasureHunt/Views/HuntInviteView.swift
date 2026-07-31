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

            Label(
                sender == nil
                    ? "This hunt doesn't say who it's from. Only accept hunts from someone you know."
                    : "\(senderName) isn't in your crew yet. Accepting adds them, so their hunts arrive straight away from now on.",
                systemImage: "person.badge.shield.checkmark"
            )
            .font(.fun(13))
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.leading)

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

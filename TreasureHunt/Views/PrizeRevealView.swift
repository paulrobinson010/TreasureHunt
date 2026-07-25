import SwiftUI

struct PrizeRevealView: View {
    let hunt: Hunt

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 84))
                .foregroundStyle(Color.brandSand)
                .shadow(radius: 8)
            Text("Treasure hunt solved!")
                .font(.fun(30, .bold))
            Text(hunt.name)
                .font(.fun(20))
                .foregroundStyle(.secondary)
            GroupBox {
                Text(hunt.prize.isEmpty
                     ? "Go and ask the hunt maker for your prize!"
                     : hunt.prize)
                    .font(.fun(20))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            } label: {
                Label("Your prize", systemImage: "gift.fill")
            }
            .padding(.horizontal)

            if hunt.role == .received, let url = try? HuntShareCodec.progressURL(for: hunt) {
                ShareLink(item: "🏆 I solved \"\(hunt.name)\" — all \(hunt.points.count) treasures found! Tap to update your map: \(url.absoluteString)") {
                    Label("Tell the hunt maker!", systemImage: "party.popper.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(.brandRed)
            }
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(OceanBackground())
    }
}

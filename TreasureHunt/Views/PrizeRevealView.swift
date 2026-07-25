import SwiftUI

struct PrizeRevealView: View {
    let hunt: Hunt

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 84))
                .foregroundStyle(.yellow)
                .shadow(radius: 8)
            Text("Treasure hunt solved!")
                .font(.title.bold())
            Text(hunt.name)
                .font(.title3)
                .foregroundStyle(.secondary)
            GroupBox {
                Text(hunt.prize.isEmpty
                     ? "Go and ask the hunt maker for your prize!"
                     : hunt.prize)
                    .font(.title3)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            } label: {
                Label("Your prize", systemImage: "gift.fill")
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }
}

import SwiftUI

/// Everything ever dug up, in one glorious chest.
struct TreasureChestView: View {
    @EnvironmentObject private var store: HuntStore

    private let columns = [GridItem(.adaptive(minimum: 104), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image("ChestBadge")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 110, height: 110)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.brandSand, lineWidth: 4))
                    .shadow(color: Color.brandSand.opacity(0.5), radius: 14)
                    .padding(.top, 16)

                if store.loot.isEmpty {
                    VStack(spacing: 8) {
                        Text("Your chest is empty!")
                            .font(.fun(20, .bold))
                            .foregroundStyle(Color.brandSand)
                        Text("Dig up treasure points on a hunt and your loot lands in here.")
                            .font(.fun(14))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 30)
                } else {
                    Text("\(store.loot.count) treasure\(store.loot.count == 1 ? "" : "s") collected")
                        .font(.fun(15, .semibold))
                        .foregroundStyle(Color.brandCyan)
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(store.loot) { item in
                            VStack(spacing: 4) {
                                Text(item.emoji)
                                    .font(.system(size: 42))
                                Text(item.name)
                                    .font(.fun(12, .semibold))
                                    .multilineTextAlignment(.center)
                                Text(item.huntName)
                                    .font(.fun(10))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 6)
                            .background(Color.brandCard, in: RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 30)
        }
        .background(OceanBackground())
        .navigationTitle("My Treasure")
        .navigationBarTitleDisplayMode(.inline)
    }
}

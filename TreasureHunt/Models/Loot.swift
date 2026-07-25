import Foundation

/// A collectible dug up at a treasure point, kept forever in the chest.
struct LootItem: Codable, Identifiable, Hashable {
    let id: UUID
    let emoji: String
    let name: String
    let huntName: String
    let date: Date
}

enum LootCatalog {
    /// The things a hunter might dig up.
    static let all: [(emoji: String, name: String)] = [
        ("💎", "Sparkly Diamond"),
        ("🪙", "Gold Doubloon"),
        ("👑", "Pirate Crown"),
        ("🦜", "Chatty Parrot"),
        ("🐚", "Singing Seashell"),
        ("⭐", "Lucky Star"),
        ("🗝️", "Mystery Key"),
        ("🏺", "Ancient Jar"),
        ("🦀", "Snappy Crab"),
        ("🐢", "Wise Turtle"),
        ("⚓", "Rusty Anchor"),
        ("🧭", "Golden Compass"),
        ("🔮", "Wizard's Orb"),
        ("🪸", "Rainbow Coral"),
        ("🦑", "Giant Squid"),
        ("💰", "Bag of Gold"),
    ]

    static func roll(huntName: String) -> LootItem {
        let pick = all.randomElement()!
        return LootItem(id: UUID(), emoji: pick.emoji, name: pick.name, huntName: huntName, date: .now)
    }
}

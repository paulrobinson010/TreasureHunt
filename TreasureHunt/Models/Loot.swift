import Foundation

/// A collectible dug up at a treasure point, kept forever in the chest.
struct LootItem: Codable, Identifiable, Hashable {
    let id: UUID
    let emoji: String
    let name: String
    let huntName: String
    let date: Date
    /// Hue rotation (degrees) applied to the emoji — turns the blue diamond
    /// into rubies, emeralds, amethysts… Nil means natural colours.
    let hue: Double?
}

enum LootCatalog {
    /// Gem-heavy by popular demand (a five-year-old's, specifically).
    /// Gems appear twice so over half of digs sparkle.
    static let all: [(emoji: String, name: String, hue: Double?)] = [
        ("💎", "Blue Diamond", 0),
        ("💎", "Ruby Red Gem", 160),
        ("💎", "Emerald Gem", -80),
        ("💎", "Amethyst Gem", 60),
        ("💎", "Golden Gem", -155),
        ("💎", "Pink Sparkle Gem", 130),
        ("💎", "Blue Diamond", 0),
        ("💎", "Ruby Red Gem", 160),
        ("💎", "Emerald Gem", -80),
        ("💎", "Amethyst Gem", 60),
        ("🪙", "Gold Doubloon", nil),
        ("👑", "Pirate Crown", nil),
        ("🦜", "Chatty Parrot", nil),
        ("⭐", "Lucky Star", nil),
        ("🗝️", "Mystery Key", nil),
        ("💰", "Bag of Gold", nil),
        ("🧭", "Golden Compass", nil),
        ("🐚", "Singing Seashell", nil),
    ]

    static func roll(huntName: String) -> LootItem {
        let pick = all.randomElement()!
        return LootItem(id: UUID(), emoji: pick.emoji, name: pick.name,
                        huntName: huntName, date: .now, hue: pick.hue)
    }
}

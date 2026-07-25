import SwiftUI

/// Brand palette lifted straight from the app icon: a treasure island at
/// night — glowing water, lime island, golden sand, and a red X.
extension Color {
    static let brandCyan = Color(red: 0.24, green: 0.78, blue: 0.89)  // water glow
    static let brandLime = Color(red: 0.72, green: 0.83, blue: 0.19)  // island green
    static let brandSand = Color(red: 0.96, green: 0.79, blue: 0.32)  // beach gold
    static let brandRed = Color(red: 0.90, green: 0.22, blue: 0.18)   // X marks the spot
    static let brandNight = Color(red: 0.016, green: 0.027, blue: 0.059)  // night sky behind the island
}

/// The app's toy-box typeface — Baloo 2, bundled in Fonts/Baloo2.ttf and
/// shared with the website.
extension Font {
    static func fun(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .custom("Baloo 2", size: size).weight(weight)
    }
}

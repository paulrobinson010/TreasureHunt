import SwiftUI

/// Brand palette lifted straight from the app icon: a treasure island at
/// night — glowing water, lime island, golden sand, and a red X.
extension Color {
    static let brandCyan = Color(red: 0.24, green: 0.78, blue: 0.89)  // water glow
    static let brandLime = Color(red: 0.72, green: 0.83, blue: 0.19)  // island green
    static let brandSand = Color(red: 0.96, green: 0.79, blue: 0.32)  // beach gold
    static let brandRed = Color(red: 0.90, green: 0.22, blue: 0.18)   // X marks the spot
    static let brandNight = Color(red: 0.016, green: 0.027, blue: 0.059)  // night sky behind the island
    static let brandDeep = Color(red: 0.03, green: 0.13, blue: 0.17)      // deeper water
    static let brandCard = Color(red: 0.05, green: 0.10, blue: 0.15)      // card surfaces, same as the website

    // The candy letters of MARKS on the logo.
    static let brandSky = Color(red: 0.31, green: 0.76, blue: 0.97)
    static let brandPurple = Color(red: 0.62, green: 0.36, blue: 0.85)
    static let brandPink = Color(red: 0.95, green: 0.38, blue: 0.66)

    /// The full candy cycle, for confetti and progress dots.
    static let candy: [Color] = [.brandSky, .brandSand, .brandLime, .brandPurple, .brandPink, .brandCyan]
}

/// The brand wordmark: red X, white -Marks, everywhere the name appears.
struct BrandWordmark: View {
    var size: CGFloat = 28

    var body: some View {
        (Text("X").foregroundStyle(Color.brandRed) + Text("-Marks").foregroundStyle(.white))
            .font(.fun(size, .bold))
    }
}

/// On-brand map marker: the island logo in a ringed circle, with an optional
/// corner badge (point number, or a green tick once found).
struct LogoMarker: View {
    enum Badge {
        case number(Int)
        case found
        case none
    }

    var badge: Badge = .none
    var ring: Color = .brandRed

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Image("AppLogo")
                .resizable()
                .scaledToFill()
                .frame(width: 38, height: 38)
                .clipShape(Circle())
                .overlay(Circle().stroke(ring, lineWidth: 3))
                .shadow(color: .black.opacity(0.4), radius: 3)
            switch badge {
            case .number(let n):
                Text("\(n)")
                    .font(.fun(12, .bold))
                    .foregroundStyle(.white)
                    .frame(width: 18, height: 18)
                    .background(ring, in: Circle())
                    .offset(x: 5, y: 5)
            case .found:
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 18, height: 18)
                    .background(Color.green, in: Circle())
                    .offset(x: 5, y: 5)
            case .none:
                EmptyView()
            }
        }
    }
}

/// The night-ocean backdrop used behind every screen: navy gradient with
/// faint glowing blobs of the island colours.
struct OceanBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [.brandNight, .brandDeep], startPoint: .top, endPoint: .bottom)
            Circle().fill(Color.brandCyan.opacity(0.13))
                .frame(width: 300).blur(radius: 80).offset(x: -120, y: -250)
            Circle().fill(Color.brandLime.opacity(0.11))
                .frame(width: 260).blur(radius: 80).offset(x: 140, y: 260)
            Circle().fill(Color.brandSand.opacity(0.08))
                .frame(width: 220).blur(radius: 90).offset(x: 130, y: -280)
            Circle().fill(Color.brandPurple.opacity(0.09))
                .frame(width: 240).blur(radius: 90).offset(x: -150, y: 200)
            Circle().fill(Color.brandPink.opacity(0.07))
                .frame(width: 200).blur(radius: 90).offset(x: 40, y: -60)
        }
        .ignoresSafeArea()
    }
}

/// The app's toy-box typeface — Baloo 2, bundled in Fonts/Baloo2.ttf and
/// shared with the website.
extension Font {
    static func fun(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .custom("Baloo 2", size: size).weight(weight)
    }
}

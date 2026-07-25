import SwiftUI

/// A moment of showing off at launch: the island logo bounces in over glowing
/// blobs of the brand colours, then the whole thing fades into the app.
struct SplashView: View {
    @State private var appeared = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.brandNight, Color(red: 0.03, green: 0.13, blue: 0.17)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            Circle().fill(Color.brandCyan.opacity(0.35))
                .frame(width: 320).blur(radius: 70).offset(x: -130, y: -220)
            Circle().fill(Color.brandLime.opacity(0.30))
                .frame(width: 280).blur(radius: 70).offset(x: 150, y: 200)
            Circle().fill(Color.brandSand.opacity(0.25))
                .frame(width: 240).blur(radius: 80).offset(x: 130, y: -280)
            Circle().fill(Color.brandRed.opacity(0.18))
                .frame(width: 200).blur(radius: 80).offset(x: -140, y: 280)

            VStack(spacing: 18) {
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 190)
                    .scaleEffect(appeared ? 1 : 0.35)
                    .rotationEffect(.degrees(appeared ? 0 : -14))
                Text("Treasure Hunt")
                    .font(.fun(36, .bold))
                    .foregroundStyle(Color.brandSand)
                    .opacity(appeared ? 1 : 0)
                Text("X marks the spot!")
                    .font(.fun(18, .medium))
                    .foregroundStyle(Color.brandCyan)
                    .opacity(appeared ? 1 : 0)
            }
            .animation(.spring(response: 0.55, dampingFraction: 0.55), value: appeared)
        }
        .onAppear { appeared = true }
    }
}

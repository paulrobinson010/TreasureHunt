import SwiftUI

/// The moment of glory: you've reached the X — now dig it up! Each tap
/// thuds, throws sand, and shrinks the mound until the treasure appears.
struct DigView: View {
    let loot: LootItem
    var onCollect: () -> Void

    private let digsNeeded = 5
    @State private var digs = 0
    @State private var particles: [SandParticle] = []
    @State private var revealed = false

    struct SandParticle: Identifiable {
        let id = UUID()
        let dx = CGFloat.random(in: -110...110)
        let dy = CGFloat.random(in: -150 ... -30)
        let size = CGFloat.random(in: 5...11)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()

            VStack(spacing: 22) {
                if revealed {
                    Text("TREASURE!")
                        .font(.fun(30, .bold))
                        .foregroundStyle(Color.brandSand)
                    Image("ChestBadge")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 130, height: 130)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.brandSand, lineWidth: 4))
                        .shadow(color: Color.brandSand.opacity(0.6), radius: 18)
                    Text(loot.emoji)
                        .font(.system(size: 64))
                        .hueRotation(.degrees(loot.hue ?? 0))
                        .saturation(loot.hue == nil ? 1 : 1.35)
                    Text("You dug up a \(loot.name)!")
                        .font(.fun(19, .semibold))
                        .foregroundStyle(.white)
                    Button {
                        onCollect()
                    } label: {
                        Text("Take it! 💰")
                            .font(.fun(18, .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 34)
                            .padding(.vertical, 13)
                            .background(Color.brandRed, in: Capsule())
                    }
                } else {
                    Text("You found the spot!")
                        .font(.fun(26, .bold))
                        .foregroundStyle(.white)
                    Text("Tap the sand to dig!")
                        .font(.fun(16, .medium))
                        .foregroundStyle(Color.brandSand)
                    ZStack {
                        ForEach(particles) { SandGrain(particle: $0) }
                        mound
                    }
                    .frame(width: 260, height: 210)
                    .contentShape(Rectangle())
                    .onTapGesture { dig() }
                }
            }
            .padding(30)
        }
        .transition(.opacity)
    }

    private var mound: some View {
        ZStack {
            Ellipse()
                .fill(Color.brandSand.opacity(0.85))
                .frame(width: 210, height: 95)
                .offset(y: 60)
            Ellipse()
                .fill(Color.brandSand)
                .frame(width: 155, height: 75)
                .offset(y: 30)
            Text("✕")
                .font(.system(size: 62, weight: .black))
                .foregroundStyle(Color.brandRed)
                .offset(y: 8)
                .opacity(1 - Double(digs) / Double(digsNeeded))
        }
        .scaleEffect(1 - 0.55 * Double(digs) / Double(digsNeeded), anchor: .bottom)
        .animation(.spring(response: 0.25, dampingFraction: 0.45), value: digs)
    }

    private func dig() {
        guard !revealed else { return }
        digs += 1
        FeedbackManager.shared.dig()
        particles.append(contentsOf: (0..<10).map { _ in SandParticle() })
        if particles.count > 60 {
            particles.removeFirst(particles.count - 60)
        }
        if digs >= digsNeeded {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) {
                revealed = true
            }
        }
    }

    private struct SandGrain: View {
        let particle: SandParticle
        @State private var flown = false

        var body: some View {
            Circle()
                .fill(Color.brandSand)
                .frame(width: particle.size, height: particle.size)
                .offset(x: flown ? particle.dx : 0, y: flown ? particle.dy : 20)
                .opacity(flown ? 0 : 1)
                .onAppear {
                    withAnimation(.easeOut(duration: 0.6)) { flown = true }
                }
        }
    }
}

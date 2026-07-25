import SwiftUI

/// A single burst of candy-coloured confetti raining down the screen.
struct ConfettiView: View {
    private struct Piece: Identifiable {
        let id: Int
        let x = Double.random(in: 0.02...0.98)
        let delay = Double.random(in: 0...0.7)
        let size = Double.random(in: 8...15)
        let colorIndex = Int.random(in: 0..<Color.candy.count)
        let spin = Double.random(in: 400...1100) * (Bool.random() ? 1 : -1)
        let duration = Double.random(in: 2.2...3.6)
    }

    private let pieces = (0..<48).map { Piece(id: $0) }
    @State private var falling = false

    var body: some View {
        GeometryReader { geo in
            ForEach(pieces) { piece in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.candy[piece.colorIndex])
                    .frame(width: piece.size, height: piece.size * 0.6)
                    .rotationEffect(.degrees(falling ? piece.spin : 0))
                    .position(
                        x: geo.size.width * piece.x,
                        y: falling ? geo.size.height + 40 : -40
                    )
                    .animation(.easeIn(duration: piece.duration).delay(piece.delay), value: falling)
            }
        }
        .allowsHitTesting(false)
        .onAppear { falling = true }
    }
}

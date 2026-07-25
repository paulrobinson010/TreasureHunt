import SwiftUI

/// Shown once the hunter is inside a point's zone. The arrow shows which way to
/// turn; when the phone points at the treasure the app buzzes and pings until
/// it's pointed away again.
struct CompassView: View {
    @ObservedObject var locationManager: LocationManager
    let target: TreasurePoint

    private var distance: Double? {
        locationManager.location.map {
            GeoMath.distance(from: $0.coordinate, to: target.coordinate)
        }
    }

    /// How far to rotate the on-screen arrow: 0 means the phone faces the treasure.
    private var pointerDelta: Double? {
        guard let location = locationManager.location,
              let heading = locationManager.headingDegrees else { return nil }
        let bearing = GeoMath.bearing(from: location.coordinate, to: target.coordinate)
        return GeoMath.angleDelta(heading, bearing)
    }

    private var onTarget: Bool {
        guard let delta = pointerDelta else { return false }
        return abs(delta) <= Config.onTargetTolerance
    }

    var body: some View {
        VStack(spacing: 14) {
            Text("You're close!")
                .font(.fun(17, .semibold))
            Image(systemName: "location.north.fill")
                .font(.system(size: 72))
                .foregroundStyle(onTarget ? .green : .secondary)
                .rotationEffect(.degrees(pointerDelta ?? 0))
                .animation(.easeInOut(duration: 0.2), value: pointerDelta)
            if let distance {
                Text(String(format: "%.0f m", distance))
                    .font(.fun(20).monospacedDigit())
            }
            Text(onTarget
                 ? "Keep going — you're pointing right at it!"
                 : "Turn slowly until the phone buzzes")
                .font(.fun(13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
        .padding()
        .onChange(of: onTarget) { _, isOn in
            if isOn {
                FeedbackManager.shared.startBuzzing()
            } else {
                FeedbackManager.shared.stopBuzzing()
            }
        }
        .onAppear {
            if onTarget { FeedbackManager.shared.startBuzzing() }
        }
        .onDisappear {
            FeedbackManager.shared.stopBuzzing()
        }
    }
}

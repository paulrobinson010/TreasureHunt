import AudioToolbox
import UIKit

/// Pings and buzzing. The buzz runs as a repeating heavy haptic with a ping
/// roughly once a second, for as long as the phone points at the treasure.
final class FeedbackManager {
    static let shared = FeedbackManager()

    private var buzzTimer: Timer?
    private let impact = UIImpactFeedbackGenerator(style: .heavy)
    private let notify = UINotificationFeedbackGenerator()

    private init() {}

    /// Short ping — entering a point's zone, and the on-target beep.
    func ping() {
        AudioServicesPlaySystemSound(1057)
    }

    /// Celebration — a point found, or the hunt solved.
    func success() {
        AudioServicesPlaySystemSound(1025)
        notify.notificationOccurred(.success)
    }

    func startBuzzing() {
        guard buzzTimer == nil else { return }
        impact.prepare()
        var tick = 0
        buzzTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.impact.impactOccurred()
            tick += 1
            if tick % 4 == 0 { self?.ping() }
        }
        buzzTimer?.fire()
    }

    func stopBuzzing() {
        buzzTimer?.invalidate()
        buzzTimer = nil
    }
}

import AVFoundation
import AudioToolbox
import CoreLocation
import UIKit

/// Pings, buzzing, and fanfares. The buzz runs as a repeating heavy haptic
/// with a ping roughly once a second, for as long as the phone points at the
/// treasure. Fanfares are bundled chiptune jingles: a small one per point,
/// a big one when the hunt is solved.
final class FeedbackManager {
    static let shared = FeedbackManager()

    private var buzzTimer: Timer?
    private var beepTimer: Timer?
    private var beepInterval: TimeInterval = 0
    private let impact = UIImpactFeedbackGenerator(style: .heavy)
    private let notify = UINotificationFeedbackGenerator()
    private var players: [String: AVAudioPlayer] = [:]

    private init() {
        // Ambient: mixes with the family's music and respects the mute switch.
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        for name in ["point-found", "hunt-solved", "detector-beep"] {
            if let url = Bundle.main.url(forResource: name, withExtension: "wav"),
               let player = try? AVAudioPlayer(contentsOf: url) {
                player.prepareToPlay()
                players[name] = player
            }
        }
    }

    /// Short ping — entering a point's zone, and the on-target beep.
    func ping() {
        AudioServicesPlaySystemSound(1057)
    }

    /// Small fanfare — one treasure point found.
    func pointFanfare() {
        play("point-found")
        notify.notificationOccurred(.success)
    }

    /// Big fanfare — every point found, hunt solved.
    func solvedFanfare() {
        play("hunt-solved")
        notify.notificationOccurred(.success)
        // A little celebratory drum-roll of thumps under the jingle.
        for delay in [0.15, 0.3, 0.45, 0.6, 0.75] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [impact] in
                impact.impactOccurred()
            }
        }
    }

    /// Metal-detector beeping: beeps while inside a point's zone, faster the
    /// closer you get. Audio carries distance; the buzz haptic carries
    /// direction — separate senses so they never drown each other out.
    func updateDetector(distance: CLLocationDistance) {
        let clamped = min(max(distance, Config.foundRadius), Config.zoneRadius)
        let closeness = (clamped - Config.foundRadius) / (Config.zoneRadius - Config.foundRadius)
        let interval = 0.15 + closeness * 1.05  // 1.2 s at the zone edge → 0.15 s on top of it
        let starting = beepTimer == nil
        guard starting || abs(interval - beepInterval) > 0.05 else { return }
        beepInterval = interval
        beepTimer?.invalidate()
        beepTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.play("detector-beep")
        }
        if starting { play("detector-beep") }
    }

    func stopDetector() {
        beepTimer?.invalidate()
        beepTimer = nil
        beepInterval = 0
    }

    /// Direction feedback: haptic-only so it layers cleanly over the detector.
    func startBuzzing() {
        guard buzzTimer == nil else { return }
        impact.prepare()
        buzzTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.impact.impactOccurred()
        }
        buzzTimer?.fire()
    }

    func stopBuzzing() {
        buzzTimer?.invalidate()
        buzzTimer = nil
    }

    private func play(_ name: String) {
        guard let player = players[name] else {
            AudioServicesPlaySystemSound(1025)
            return
        }
        player.currentTime = 0
        player.play()
    }
}

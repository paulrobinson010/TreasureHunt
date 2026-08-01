import SwiftUI

/// A grown-up check in front of the things children shouldn't do alone.
///
/// On a grown-up's phone that's a sum written in words — enough to keep a
/// child from wandering into hunt-making. On a young hunter's phone it is the
/// grown-up's passcode instead, because a sum only proves someone can do
/// arithmetic, and a stranger can talk a child through arithmetic.
@MainActor
final class ParentGate: ObservableObject {
    @Published var challenge: Challenge?
    @Published var wrongAnswer = false

    /// A hunter's phone re-locks the moment the app goes away — that's where
    /// the risk is. A grown-up's own phone asks once per launch: it sits
    /// behind their own device lock already, and a sum every ten minutes just
    /// trains people to resent it.
    private var unlockedThisSession = false
    private var unlockedUntil = Date.distantPast
    private let unlockMinutes: TimeInterval = 10 * 60
    private var pending: (() -> Void)?

    private var isUnlocked: Bool {
        DeviceSetup.isHunterPhone ? unlockedUntil > .now : unlockedThisSession
    }

    enum Challenge {
        case sum(a: Int, b: Int)
        case passcode

        var prompt: String {
            switch self {
            case .sum(let a, let b): "\(Self.word(a)) × \(Self.word(b))"
            case .passcode: "Enter the grown-up passcode"
            }
        }

        static func sum() -> Challenge {
            .sum(a: Int.random(in: 3...9), b: Int.random(in: 4...12))
        }

        private static func word(_ n: Int) -> String {
            let words = ["zero", "one", "two", "three", "four", "five", "six",
                         "seven", "eight", "nine", "ten", "eleven", "twelve"]
            return n < words.count ? words[n] : "\(n)"
        }
    }

    /// Runs `action` now if a grown-up has recently proved themselves,
    /// otherwise asks first.
    func guarding(_ action: @escaping () -> Void) {
        if isUnlocked {
            action()
            return
        }
        pending = action
        wrongAnswer = false
        challenge = nextChallenge()
    }

    private func nextChallenge() -> Challenge {
        // A hunter's phone always needs the passcode set by the grown-up who
        // handed the phone over. Only if none was set does it fall back.
        if DeviceSetup.isHunterPhone, DeviceSetup.hasPasscode {
            return .passcode
        }
        return .sum()
    }

    func submit(_ text: String) {
        guard let challenge else { return }
        let ok: Bool
        switch challenge {
        case .sum(let a, let b):
            ok = Int(text.trimmingCharacters(in: .whitespaces)) == a * b
        case .passcode:
            ok = DeviceSetup.verify(text)
        }
        guard ok else {
            wrongAnswer = true
            // A fresh sum each time, so guessing can't wear it down.
            if case .sum = challenge { self.challenge = .sum() }
            return
        }
        unlockedUntil = .now.addingTimeInterval(unlockMinutes)
        unlockedThisSession = true
        self.challenge = nil
        let action = pending
        pending = nil
        action?()
    }

    func cancel() {
        challenge = nil
        pending = nil
    }

    /// Re-lock when the app has been away — a phone handed back to a child
    /// shouldn't still be open for business. Only meaningful on a hunter's
    /// phone; a grown-up's stays unlocked until the app is quit.
    func lock() {
        unlockedUntil = .distantPast
    }
}

struct ParentGateView: View {
    @ObservedObject var gate: ParentGate
    let challenge: ParentGate.Challenge

    @State private var typed = ""
    @FocusState private var focused: Bool

    private var isPasscode: Bool {
        if case .passcode = challenge { return true }
        return false
    }

    private var lockoutMessage: String? {
        let seconds = Int(DeviceSetup.lockedOutFor.rounded(.up))
        guard seconds > 0 else { return nil }
        return "Too many tries. Wait \(seconds) second\(seconds == 1 ? "" : "s") and try again."
    }

    var body: some View {
        VStack(spacing: 18) {
            Text("🔒")
                .font(.system(size: 46))
            Text("Ask a grown-up!")
                .font(.fun(24, .bold))
                .foregroundStyle(Color.brandSand)

            if isPasscode {
                Text("This is a young hunter's phone. The grown-up who set it up has the passcode.")
                    .font(.fun(14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("Grown-ups make the hunts. What is…")
                    .font(.fun(14))
                    .foregroundStyle(.secondary)
                Text(challenge.prompt)
                    .font(.fun(30, .bold))
                    .foregroundStyle(Color.brandCyan)
                    .multilineTextAlignment(.center)
            }

            SecureOrPlainField(text: $typed, secure: isPasscode)
                .focused($focused)

            if gate.wrongAnswer {
                Text(lockoutMessage ?? (isPasscode ? "That passcode isn't right." : "Not quite — have another go."))
                    .font(.fun(13))
                    .foregroundStyle(Color.brandRed)
                    .multilineTextAlignment(.center)
            }

            Button {
                gate.submit(typed)
                typed = ""
            } label: {
                Text("Check")
                    .font(.fun(18, .bold))
                    .foregroundStyle(Color.brandNight)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(
                        LinearGradient(colors: [.brandCyan, .brandLime],
                                       startPoint: .leading, endPoint: .trailing),
                        in: Capsule()
                    )
            }
            .disabled(typed.isEmpty)

            Button("Cancel") { gate.cancel() }
                .font(.fun(15))
                .foregroundStyle(.secondary)
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(OceanBackground())
        .onAppear { focused = true }
    }
}

/// Passcodes are masked; sums aren't — a grown-up shouldn't have to type
/// blind to prove they can multiply.
struct SecureOrPlainField: View {
    @Binding var text: String
    let secure: Bool

    var body: some View {
        Group {
            if secure {
                SecureField("Passcode", text: $text)
            } else {
                TextField("Answer", text: $text)
            }
        }
        .keyboardType(.numberPad)
        .multilineTextAlignment(.center)
        .font(.fun(24, .bold).monospacedDigit())
        .padding(.vertical, 10)
        .background(Color.brandCard, in: RoundedRectangle(cornerRadius: 14))
    }
}

extension View {
    /// Presents the grown-up check whenever the gate raises one.
    func parentGate(_ gate: ParentGate) -> some View {
        sheet(isPresented: Binding(
            get: { gate.challenge != nil },
            set: { if !$0 { gate.cancel() } }
        )) {
            if let challenge = gate.challenge {
                ParentGateView(gate: gate, challenge: challenge)
                    .presentationDetents([.medium])
            }
        }
    }
}

import SwiftUI

/// A grown-up check in front of the things children shouldn't do alone:
/// making hunts (which means placing real-world locations) and changing who
/// is allowed to send hunts to this phone.
///
/// The sum is written in words, so it needs reading *and* arithmetic — a
/// five-year-old bounces off it, a grown-up barely notices it.
@MainActor
final class ParentGate: ObservableObject {
    @Published var challenge: Challenge?
    @Published var wrongAnswer = false

    /// One pass covers a stretch of grown-up work — nobody wants a sum
    /// between every hunt they make.
    private var unlockedUntil = Date.distantPast
    private let unlockMinutes: TimeInterval = 10 * 60
    private var pending: (() -> Void)?

    struct Challenge {
        let a: Int
        let b: Int

        var answer: Int { a * b }
        var question: String { "\(Self.word(a)) × \(Self.word(b))" }

        static func random() -> Challenge {
            Challenge(a: Int.random(in: 3...9), b: Int.random(in: 4...12))
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
        if unlockedUntil > .now {
            action()
            return
        }
        pending = action
        wrongAnswer = false
        challenge = .random()
    }

    func submit(_ text: String) {
        guard let challenge, let answer = Int(text.trimmingCharacters(in: .whitespaces)) else {
            wrongAnswer = true
            return
        }
        guard answer == challenge.answer else {
            // A fresh sum each time, so guessing can't wear it down.
            wrongAnswer = true
            self.challenge = .random()
            return
        }
        unlockedUntil = .now.addingTimeInterval(unlockMinutes)
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
    /// shouldn't still be open for business.
    func lock() {
        unlockedUntil = .distantPast
    }
}

struct ParentGateView: View {
    @ObservedObject var gate: ParentGate
    let challenge: ParentGate.Challenge

    @State private var typed = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 18) {
            Text("🔒")
                .font(.system(size: 46))
            Text("Ask a grown-up!")
                .font(.fun(24, .bold))
                .foregroundStyle(Color.brandSand)
            Text("Grown-ups make the hunts. What is…")
                .font(.fun(14))
                .foregroundStyle(.secondary)

            Text(challenge.question)
                .font(.fun(30, .bold))
                .foregroundStyle(Color.brandCyan)
                .multilineTextAlignment(.center)

            TextField("Answer", text: $typed)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.fun(24, .bold).monospacedDigit())
                .padding(.vertical, 10)
                .background(Color.brandCard, in: RoundedRectangle(cornerRadius: 14))
                .focused($focused)

            if gate.wrongAnswer {
                Text("Not quite — have another go.")
                    .font(.fun(13))
                    .foregroundStyle(Color.brandRed)
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

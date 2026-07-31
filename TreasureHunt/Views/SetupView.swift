import SwiftUI

/// First run: a grown-up says what this phone is for. Everything else in
/// X-Marks hangs off the answer, so it's asked once, up front, behind a
/// grown-up check.
struct SetupView: View {
    var onDone: () -> Void = {}

    private enum Step {
        case chooseRole
        case setPasscode
        case confirmPasscode
    }

    @State private var step: Step = .chooseRole
    @State private var passcode = ""
    @State private var firstEntry = ""
    @State private var error: String?
    @StateObject private var gate = ParentGate()
    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            OceanBackground()
            ScrollView {
                VStack(spacing: 22) {
                    Image("BrandLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 130)
                        .padding(.top, 30)

                    switch step {
                    case .chooseRole: chooseRole
                    case .setPasscode, .confirmPasscode: passcodeStep
                    }
                }
                .padding(26)
            }
        }
        .parentGate(gate)
    }

    private var chooseRole: some View {
        VStack(spacing: 16) {
            Text("Who is this phone for?")
                .font(.fun(24, .bold))
                .foregroundStyle(Color.brandSand)
            Text("A grown-up should answer this.")
                .font(.fun(14))
                .foregroundStyle(.secondary)

            Button {
                // A sum is enough here: it only has to stop a child picking
                // the grown-up option on their own phone.
                gate.guarding {
                    DeviceSetup.setRole(.grownUp)
                    onDone()
                }
            } label: {
                roleCard(
                    emoji: "🧭",
                    title: "A grown-up's phone",
                    detail: "Make treasure hunts, choose who can send hunts to your hunters, and go hunting too.",
                    tint: .brandCyan
                )
            }

            Button {
                gate.guarding { step = .setPasscode }
            } label: {
                roleCard(
                    emoji: "🏴‍☠️",
                    title: "A young hunter's phone",
                    detail: "Hunting only. No making hunts, and hunts can only arrive from grown-ups you add — nobody else can send one, whoever has the number.",
                    tint: .brandLime
                )
            }

            Text("You can change this later, but on a hunter's phone it takes the grown-up passcode.")
                .font(.fun(12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        }
    }

    private func roleCard(emoji: String, title: String, detail: String, tint: Color) -> some View {
        VStack(spacing: 6) {
            Text(emoji).font(.system(size: 36))
            Text(title)
                .font(.fun(19, .bold))
                .foregroundStyle(tint)
            Text(detail)
                .font(.fun(13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(Color.brandCard, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(tint.opacity(0.5), lineWidth: 2))
    }

    private var passcodeStep: some View {
        VStack(spacing: 16) {
            Text(step == .setPasscode ? "Pick a grown-up passcode" : "Type it once more")
                .font(.fun(22, .bold))
                .foregroundStyle(Color.brandSand)
            Text("This phone will ask for it before anything a grown-up should decide — like adding someone who's allowed to send hunts. Don't share it with your hunter.")
                .font(.fun(13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            SecureOrPlainField(text: $passcode, secure: true)
                .focused($focused)

            if let error {
                Text(error)
                    .font(.fun(13))
                    .foregroundStyle(Color.brandRed)
            }

            Button {
                advancePasscode()
            } label: {
                Text(step == .setPasscode ? "Next" : "Finish")
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
            .disabled(passcode.count < 4)

            Button("Back") {
                step = .chooseRole
                passcode = ""
                firstEntry = ""
                error = nil
            }
            .font(.fun(15))
            .foregroundStyle(.secondary)
        }
        .onAppear { focused = true }
    }

    private func advancePasscode() {
        error = nil
        if step == .setPasscode {
            guard passcode.count >= 4 else {
                error = "Use at least four digits."
                return
            }
            firstEntry = passcode
            passcode = ""
            step = .confirmPasscode
        } else {
            guard passcode == firstEntry else {
                error = "Those didn't match — start again."
                passcode = ""
                firstEntry = ""
                step = .setPasscode
                return
            }
            DeviceSetup.setPasscode(passcode)
            DeviceSetup.setRole(.hunter)
            onDone()
        }
    }
}

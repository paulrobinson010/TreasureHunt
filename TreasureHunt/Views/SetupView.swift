import SwiftUI

/// First run, start to finish. A grown-up says what the phone is, names
/// themselves, and sends their hunting card — because without that card no
/// hunt they send will ever open, and discovering that by trial and error is
/// a miserable first ten minutes.
struct SetupView: View {
    var onDone: () -> Void = {}

    private enum Step {
        case chooseRole
        case name
        case sendCard
        case setPasscode
        case confirmPasscode
        case addGrownUps
    }

    @State private var step: Step = .chooseRole
    @State private var chosenRole: DeviceRole?
    @State private var myName = ""
    @State private var passcode = ""
    @State private var firstEntry = ""
    @State private var error: String?
    @State private var cardURL: URL?
    @State private var cardShared = false
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
                        .frame(height: step == .chooseRole ? 130 : 90)
                        .padding(.top, 24)

                    switch step {
                    case .chooseRole: chooseRole
                    case .name: nameStep
                    case .sendCard: sendCardStep
                    case .setPasscode, .confirmPasscode: passcodeStep
                    case .addGrownUps: addGrownUpsStep
                    }
                }
                .padding(26)
            }
        }
        .parentGate(gate)
    }

    // MARK: 1. What is this phone?

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
                    chosenRole = .grownUp
                    step = .name
                }
            } label: {
                roleCard(
                    emoji: "🧭",
                    title: "A grown-up's phone",
                    detail: "Make treasure hunts and send them to your hunters.",
                    tint: .brandCyan
                )
            }

            Button {
                gate.guarding {
                    chosenRole = .hunter
                    step = .setPasscode
                }
            } label: {
                roleCard(
                    emoji: "🏴‍☠️",
                    title: "A young hunter's phone",
                    detail: "Hunting only. Hunts open only if they come from a grown-up you've added — nobody else can send one, whoever has the number.",
                    tint: .brandLime
                )
            }
        }
    }

    // MARK: 2a. Grown-up: name, then card

    private var nameStep: some View {
        VStack(spacing: 16) {
            Text("What should hunters call you?")
                .font(.fun(23, .bold))
                .foregroundStyle(Color.brandSand)
            Text("This name goes on every hunt you send, so your hunters know it's from you.")
                .font(.fun(13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            TextField("Mum, Dad, Grandma…", text: $myName)
                .multilineTextAlignment(.center)
                .font(.fun(22, .bold))
                .padding(.vertical, 10)
                .background(Color.brandCard, in: RoundedRectangle(cornerRadius: 14))
                .focused($focused)

            primaryButton("Next") {
                HunterIdentity.name = myName.trimmingCharacters(in: .whitespaces)
                cardURL = try? HuntShareCodec.crewInviteURL()
                step = .sendCard
            }
            .disabled(myName.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .onAppear { focused = true }
    }

    private var sendCardStep: some View {
        VStack(spacing: 16) {
            Text("Send your hunting card")
                .font(.fun(23, .bold))
                .foregroundStyle(Color.brandSand)

            VStack(alignment: .leading, spacing: 10) {
                Label("A hunter's phone only opens hunts from grown-ups it already knows.", systemImage: "lock.shield.fill")
                Label("Your card is how they get to know you. Send it, then open it on their phone with their passcode.", systemImage: "person.badge.plus")
                Label("Do this once per hunter. After that, every hunt you send just works.", systemImage: "checkmark.seal.fill")
            }
            .font(.fun(13))
            .foregroundStyle(.secondary)
            .padding(16)
            .background(Color.brandCard, in: RoundedRectangle(cornerRadius: 18))

            if let cardURL {
                ShareLink(item: cardMessage(cardURL)) {
                    Text("Send my hunting card")
                        .font(.fun(18, .bold))
                        .foregroundStyle(Color.brandNight)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(colors: [.brandCyan, .brandLime],
                                           startPoint: .leading, endPoint: .trailing),
                            in: Capsule()
                        )
                }
                .simultaneousGesture(TapGesture().onEnded { cardShared = true })
            }

            Button(cardShared ? "Done — start hunting!" : "I'll do this later") {
                finish()
            }
            .font(.fun(15, cardShared ? .bold : .regular))
            .foregroundStyle(cardShared ? Color.brandLime : .secondary)

            if !cardShared {
                Text("You can send it any time from My Crew — but hunts won't open on a hunter's phone until you do.")
                    .font(.fun(12))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: 2b. Hunter: passcode, then grown-ups

    private var passcodeStep: some View {
        VStack(spacing: 16) {
            Text(step == .setPasscode ? "Pick a grown-up passcode" : "Type it once more")
                .font(.fun(22, .bold))
                .foregroundStyle(Color.brandSand)
            Text("This phone asks for it before anything a grown-up should decide — like adding someone who's allowed to send hunts. Don't let your hunter see you type it.")
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

            primaryButton(step == .setPasscode ? "Next" : "Save") {
                advancePasscode()
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

    private var addGrownUpsStep: some View {
        VStack(spacing: 16) {
            Text("Add your grown-ups")
                .font(.fun(23, .bold))
                .foregroundStyle(Color.brandSand)

            VStack(alignment: .leading, spacing: 10) {
                Label("Ask each grown-up to send their hunting card from X-Marks on their phone.", systemImage: "paperplane.fill")
                Label("Open the card here and type this phone's passcode to add them.", systemImage: "lock.open.fill")
                Label("Only their hunts will open on this phone. Everything else is turned away.", systemImage: "hand.raised.fill")
            }
            .font(.fun(13))
            .foregroundStyle(.secondary)
            .padding(16)
            .background(Color.brandCard, in: RoundedRectangle(cornerRadius: 18))

            primaryButton("Ready to hunt!") { finish() }
        }
    }

    // MARK: Plumbing

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.fun(18, .bold))
                .foregroundStyle(Color.brandNight)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(colors: [.brandCyan, .brandLime],
                                   startPoint: .leading, endPoint: .trailing),
                    in: Capsule()
                )
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

    private func cardMessage(_ url: URL) -> String {
        "🏴‍☠️ \(HunterIdentity.name) is setting up X-Marks treasure hunts! Open this on the hunter's phone to add them as a trusted grown-up: \(url.absoluteString)"
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
            step = .addGrownUps
        }
    }

    /// The role is committed last: writing it is what dismisses setup, so it
    /// must not happen until the whole flow is done.
    private func finish() {
        guard let chosenRole else { return }
        DeviceSetup.setRole(chosenRole)
        onDone()
    }
}

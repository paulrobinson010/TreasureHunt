import SwiftUI

@main
struct TreasureHuntApp: App {
    @StateObject private var store = HuntStore()
    @StateObject private var crew = CrewStore()
    @StateObject private var gate = ParentGate()
    @State private var showSplash = true

    init() {
        // Put the toy-box font and sand-gold colour on navigation titles —
        // SwiftUI's environment font doesn't reach the navigation bar.
        let sand = UIColor(red: 0.96, green: 0.79, blue: 0.32, alpha: 1)
        let nav = UINavigationBar.appearance()
        var title: [NSAttributedString.Key: Any] = [.foregroundColor: sand]
        var largeTitle: [NSAttributedString.Key: Any] = [.foregroundColor: sand]
        if let font = UIFont(name: "Baloo2-SemiBold", size: 18) { title[.font] = font }
        if let font = UIFont(name: "Baloo2-Bold", size: 32) { largeTitle[.font] = font }
        nav.titleTextAttributes = title
        nav.largeTitleTextAttributes = largeTitle
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environmentObject(store)
                    .environmentObject(crew)
                    .environmentObject(gate)
                    .environment(\.font, .fun(17))
                if showSplash {
                    SplashView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .preferredColorScheme(.dark)
            .tint(.brandCyan)
            .task {
                try? await Task.sleep(for: .seconds(1.8))
                withAnimation(.easeOut(duration: 0.45)) { showSplash = false }
            }
        }
    }
}

enum ImportResult {
    case imported(String, from: String?)
    case duplicate(String)
    case crewJoined(String, isNew: Bool)
    case senderNotAllowed(String?)
    case failed

    var message: String {
        switch self {
        case .imported(let name, let from):
            if let from {
                return "\"\(name)\" from \(from) was added to your hunts. Happy hunting!"
            }
            return "\"\(name)\" was added to your hunts. Happy hunting!"
        case .crewJoined(let name, let isNew):
            return isNew
                ? "\(name) has joined your crew! Send your card back so they can add you too."
                : "\(name) is already in your crew."
        case .senderNotAllowed(let name):
            let who = name ?? "Whoever sent that hunt"
            return """
            That hunt is from \(who), who isn't one of your grown-ups yet, so it didn't open.

            Ask \(who) to send their hunting card from X-Marks — open that card here with the grown-up passcode, and their hunts will work from then on.
            """
        case .duplicate(let name):
            return "You already have \"\(name)\"."
        case .failed:
            return "That link didn't contain a valid treasure hunt."
        }
    }
}

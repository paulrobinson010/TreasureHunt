import SwiftUI

@main
struct TreasureHuntApp: App {
    @StateObject private var store = HuntStore()
    @State private var importResult: ImportResult?
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
            .onOpenURL { handle(url: $0) }
            .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                if let url = activity.webpageURL { handle(url: url) }
            }
            .alert(
                "X-Marks",
                isPresented: Binding(
                    get: { importResult != nil },
                    set: { if !$0 { importResult = nil } }
                ),
                presenting: importResult
            ) { _ in
                Button("OK") {}
            } message: { result in
                Text(result.message)
            }
        }
    }

    private func handle(url: URL) {
        switch HuntShareCodec.decode(url: url) {
        case .hunt(let hunt):
            importResult = store.importHunt(hunt) ? .imported(hunt.name) : .duplicate(hunt.name)
        case .progress(let report):
            if let updated = store.applyProgress(report) {
                importResult = .progress(updated.name, updated.foundPointIDs.count, updated.points.count)
            } else {
                importResult = .progressUnknown(report.name)
            }
        case nil:
            importResult = .failed
        }
    }
}

enum ImportResult {
    case imported(String)
    case duplicate(String)
    case progress(String, Int, Int)
    case progressUnknown(String)
    case failed

    var message: String {
        switch self {
        case .imported(let name): "\"\(name)\" was added to your hunts. Happy hunting!"
        case .duplicate(let name): "You already have \"\(name)\"."
        case .progress(let name, let found, let total):
            found == total
                ? "\"\(name)\" is SOLVED — all \(total) treasures found! 🎉"
                : "\"\(name)\": \(found) of \(total) treasures found so far!"
        case .progressUnknown(let name):
            "That progress update is for \"\(name)\", which isn't on this phone."
        case .failed: "That link didn't contain a valid treasure hunt."
        }
    }
}

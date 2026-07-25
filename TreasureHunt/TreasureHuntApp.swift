import SwiftUI

@main
struct TreasureHuntApp: App {
    @StateObject private var store = HuntStore()
    @State private var importResult: ImportResult?

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .onOpenURL { handle(url: $0) }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                    if let url = activity.webpageURL { handle(url: url) }
                }
                .alert(
                    "Treasure Hunt",
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
        guard let hunt = HuntShareCodec.hunt(fromURL: url) else {
            importResult = .failed
            return
        }
        importResult = store.importHunt(hunt) ? .imported(hunt.name) : .duplicate(hunt.name)
    }
}

enum ImportResult {
    case imported(String)
    case duplicate(String)
    case failed

    var message: String {
        switch self {
        case .imported(let name): "\"\(name)\" was added to your hunts. Happy hunting!"
        case .duplicate(let name): "You already have \"\(name)\"."
        case .failed: "That link didn't contain a valid treasure hunt."
        }
    }
}

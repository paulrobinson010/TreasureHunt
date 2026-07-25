import SwiftUI
import UIKit

struct ShareHuntView: View {
    let hunt: Hunt
    @Environment(\.dismiss) private var dismiss

    @State private var link: URL?
    @State private var file: URL?
    @State private var copied = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Send this hunt over iMessage, WhatsApp or anything else. The hunt is encrypted and travels inside the link itself — tapping it opens straight into the Treasure Hunt app. If a link won't tap, the kids can copy the whole message and use Import in their app, or you can send the file instead.")
                        .font(.fun(13))
                        .foregroundStyle(.secondary)
                }
                if let link {
                    Section("Send as link (recommended)") {
                        ShareLink(item: shareMessage(for: link)) {
                            Label("Share link", systemImage: "link")
                        }
                        Button {
                            UIPasteboard.general.string = link.absoluteString
                            copied = true
                        } label: {
                            Label(copied ? "Copied!" : "Copy link", systemImage: copied ? "checkmark" : "doc.on.doc")
                        }
                    }
                }
                if let file {
                    Section("Send as file") {
                        ShareLink(item: file) {
                            Label("Share \(hunt.name).treasurehunt", systemImage: "square.and.arrow.up")
                        }
                    }
                }
            }
            .navigationTitle("Share \"\(hunt.name)\"")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                link = try? HuntShareCodec.url(for: hunt)
                file = try? HuntShareCodec.exportFile(for: hunt)
            }
        }
    }

    private func shareMessage(for url: URL) -> String {
        "🏴‍☠️ Treasure hunt: \"\(hunt.name)\"! Tap to open it in the Treasure Hunt app: \(url.absoluteString)"
    }
}

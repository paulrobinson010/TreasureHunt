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
                    Text("Send this hunt over iMessage, WhatsApp or anything else. The file is the most reliable — tapping it opens straight into the Treasure Hunt app. If you send the link, the kids can also copy the whole message and use Import in their app.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                if let file {
                    Section("Send as file (recommended)") {
                        ShareLink(item: file) {
                            Label("Share \(hunt.name).treasurehunt", systemImage: "square.and.arrow.up")
                        }
                    }
                }
                if let link {
                    Section("Send as link") {
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
        "🏴‍☠️ Treasure hunt: \"\(hunt.name)\"! Open the Treasure Hunt app, tap Import, and paste this message: \(url.absoluteString)"
    }
}

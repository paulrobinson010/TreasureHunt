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
            VStack(spacing: 18) {
                Image("BrandLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 110)

                Text("\"\(hunt.name)\" is ready!")
                    .font(.fun(22, .bold))
                    .foregroundStyle(Color.brandSand)
                    .multilineTextAlignment(.center)

                if let link {
                    ShareLink(item: shareMessage(for: link)) {
                        Label("Send this hunt", systemImage: "paperplane.fill")
                            .font(.fun(19, .bold))
                            .foregroundStyle(Color.brandNight)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(
                                LinearGradient(colors: [.brandCyan, .brandLime],
                                               startPoint: .leading, endPoint: .trailing),
                                in: Capsule()
                            )
                    }
                }

                Text("Sent as \(HunterIdentity.name). The first hunt you send someone needs a grown-up on their phone to tap Accept — after that, your hunts arrive straight away.")
                    .font(.fun(13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Spacer()

                HStack(spacing: 22) {
                    if let link {
                        Button {
                            UIPasteboard.general.string = link.absoluteString
                            copied = true
                        } label: {
                            Label(copied ? "Copied!" : "Copy link",
                                  systemImage: copied ? "checkmark" : "doc.on.doc")
                                .font(.fun(14))
                        }
                    }
                    if let file {
                        ShareLink(item: file) {
                            Label("Send as file", systemImage: "doc.fill")
                                .font(.fun(14))
                        }
                    }
                }
                .foregroundStyle(Color.brandCyan)
                .padding(.bottom, 8)
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(OceanBackground())
            .navigationTitle("Share")
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
        "🏴‍☠️ \(HunterIdentity.name) has sent you a treasure hunt: \"\(hunt.name)\"! Tap to open it in X-Marks: \(url.absoluteString)"
    }
}

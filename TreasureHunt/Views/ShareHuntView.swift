import SwiftUI
import UIKit

struct ShareHuntView: View {
    let hunt: Hunt
    @Environment(\.dismiss) private var dismiss

    @State private var link: URL?
    @State private var file: URL?
    @State private var cardURL: URL?
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

                Text("Sent as \(HunterIdentity.name).")
                    .font(.fun(13))
                    .foregroundStyle(.secondary)

                VStack(spacing: 8) {
                    Label("Sending to a hunter for the first time?", systemImage: "info.circle.fill")
                        .font(.fun(13, .semibold))
                        .foregroundStyle(Color.brandSand)
                    Text("Their phone turns away hunts from grown-ups it doesn't know yet. Send them your hunting card too — they open it once with their passcode, and every hunt after that just works.")
                        .font(.fun(12))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    if let cardURL {
                        ShareLink(item: cardMessage(cardURL)) {
                            Label("Send my hunting card", systemImage: "person.badge.plus")
                                .font(.fun(14, .semibold))
                                .foregroundStyle(Color.brandCyan)
                        }
                    }
                }
                .padding(14)
                .background(Color.brandCard, in: RoundedRectangle(cornerRadius: 18))

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
                cardURL = try? HuntShareCodec.crewInviteURL()
            }
        }
    }

    private func cardMessage(_ url: URL) -> String {
        "🏴‍☠️ \(HunterIdentity.name) here! Open this on the hunter's phone to add me as a trusted grown-up in X-Marks: \(url.absoluteString)"
    }

    private func shareMessage(for url: URL) -> String {
        "🏴‍☠️ \(HunterIdentity.name) has sent you a treasure hunt: \"\(hunt.name)\"! Tap to open it in X-Marks: \(url.absoluteString)"
    }
}

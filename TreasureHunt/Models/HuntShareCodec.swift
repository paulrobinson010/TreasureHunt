import CryptoKit
import Foundation

/// Encodes a hunt into a link or file so it can be sent over iMessage/WhatsApp
/// with no server involved — the whole hunt travels inside the link/file as
/// compressed, encrypted ciphertext that only the app can read.
enum HuntShareCodec {
    static let scheme = "treasurehunt"
    static let fileExtension = "treasurehunt"
    /// Universal-link host — links are tappable in iMessage/WhatsApp and open
    /// straight into the app; the website is only a fallback for phones
    /// without the app installed.
    static let webHost = "x-marks.robbo-online.uk"
    /// Pre-rebrand host, still accepted on import so old links keep working.
    static let legacyWebHost = "treasurehunt.robbo-online.uk"

    /// Only what the recipient needs. Nothing travels back the other way:
    /// there is deliberately no channel for a hunt's creator to learn who
    /// found what, or when.
    private struct Payload: Codable {
        var id: UUID
        var name: String
        var prize: String
        var points: [TreasurePoint]
        var sequential: Bool?
        var startsAt: Date?
        var endsAt: Date?
    }

    /// Wraps the payload with the sender's signature, so the recipient can
    /// tell a hunt from someone in their crew apart from one that just turned
    /// up. Older links carry a bare Payload and still decode.
    private struct Envelope: Codable {
        var payload: Data
        var senderName: String?
        var senderKey: Data?
        var signature: Data?
    }

    /// Everything a shared link can contain.
    enum Decoded {
        case hunt(Hunt, sender: CrewCard?)
        case crewInvite(CrewCard)
    }

    // MARK: Encoding

    /// JSON → sign → zlib compress → AES-GCM encrypt. The wire format for both
    /// links and files.
    static func sealedData(for hunt: Hunt) throws -> Data {
        let payload = try JSONEncoder().encode(
            Payload(id: hunt.id, name: hunt.name, prize: hunt.prize, points: hunt.points,
                    sequential: hunt.sequential, startsAt: hunt.startsAt, endsAt: hunt.endsAt)
        )
        let envelope = Envelope(
            payload: payload,
            senderName: HunterIdentity.name,
            senderKey: HunterIdentity.publicKey.rawRepresentation,
            signature: HunterIdentity.sign(payload)
        )
        let raw = try JSONEncoder().encode(envelope)
        let compressed = try (raw as NSData).compressed(using: .zlib) as Data
        return try HuntCrypto.encrypt(compressed)
    }

    /// https://x-marks.robbo-online.uk/crew/?k=<sealed card> — a handshake
    /// invite, so two hunters can agree to swap hunts from then on.
    static func crewInviteURL() throws -> URL {
        let raw = try JSONEncoder().encode(HunterIdentity.card)
        let compressed = try (raw as NSData).compressed(using: .zlib) as Data
        let sealed = try HuntCrypto.encrypt(compressed)
        guard let url = URL(string: "https://\(webHost)/crew/?k=\(base64url(sealed))") else {
            throw CocoaError(.coderInvalidValue)
        }
        return url
    }

    static func crewCard(fromCode code: String) -> CrewCard? {
        guard let sealed = base64urlDecode(code),
              let compressed = try? HuntCrypto.decrypt(sealed),
              let raw = try? (compressed as NSData).decompressed(using: .zlib) as Data else { return nil }
        return try? JSONDecoder().decode(CrewCard.self, from: raw)
    }

    /// https://treasurehunt.robbo-online.uk/hunt/?d=<base64url sealed payload>
    static func url(for hunt: Hunt) throws -> URL {
        guard let url = URL(string: "https://\(webHost)/hunt/?d=\(base64url(try sealedData(for: hunt)))") else {
            throw CocoaError(.coderInvalidValue)
        }
        return url
    }

    private static func base64url(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    /// Writes a shareable .treasurehunt file (same sealed format as links)
    /// to the temporary directory.
    static func exportFile(for hunt: Hunt) throws -> URL {
        let safeName = hunt.name.replacingOccurrences(of: "/", with: "-")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(safeName.isEmpty ? "Hunt" : safeName)
            .appendingPathExtension(fileExtension)
        try sealedData(for: hunt).write(to: url, options: .atomic)
        return url
    }

    // MARK: Decoding

    /// Routes any incoming link/file to what it contains: a hunt, or a crew
    /// handshake invite.
    static func decode(url: URL) -> Decoded? {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        func query(_ name: String) -> String? {
            components?.queryItems?.first { $0.name == name }?.value
        }
        // Which section of the site (or which custom-scheme host) is this?
        let section: String? = {
            if url.scheme == scheme { return url.host?.lowercased() }
            if url.scheme == "https" || url.scheme == "http", isOurHost(url.host) {
                return url.pathComponents.count > 1 ? url.pathComponents[1] : nil
            }
            return nil
        }()

        if section == "crew", let code = query("k") {
            return crewCard(fromCode: code).map { .crewInvite($0) }
        }
        if let code = query("d"), let found = huntAndSender(fromCode: code) {
            return .hunt(found.0, sender: found.1)
        }
        return huntAndSender(fromURL: url).map { .hunt($0.0, sender: $0.1) }
    }

    /// Handles universal links, legacy treasurehunt:// links, and opened
    /// .treasurehunt files.
    static func huntAndSender(fromURL url: URL) -> (Hunt, CrewCard?)? {
        if url.isFileURL {
            let secured = url.startAccessingSecurityScopedResource()
            defer { if secured { url.stopAccessingSecurityScopedResource() } }
            guard let data = try? Data(contentsOf: url) else { return nil }
            return huntAndSender(fromData: data)
        }
        if url.scheme == "https" || url.scheme == "http" {
            guard isOurHost(url.host) else { return nil }
            // https://host/hunt/?d=<code>
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let code = components.queryItems?.first(where: { $0.name == "d" })?.value {
                return huntAndSender(fromCode: code)
            }
            // https://host/hunt/<code>
            if url.pathComponents.count > 2, url.pathComponents[1] == "hunt" {
                return huntAndSender(fromCode: url.pathComponents[2])
            }
            return nil
        }
        guard url.scheme == scheme else { return nil }
        // treasurehunt://hunt/<code> — "hunt" is the host, the code is the path.
        let code = url.pathComponents.count > 1 ? url.pathComponents[1] : (url.host ?? "")
        return huntAndSender(fromCode: code)
    }

    static func huntAndSender(fromCode code: String) -> (Hunt, CrewCard?)? {
        guard let sealed = base64urlDecode(code) else { return nil }
        return huntAndSender(fromData: sealed)
    }

    private static func isOurHost(_ host: String?) -> Bool {
        let host = host?.lowercased()
        return host == webHost || host == legacyWebHost
    }

    private static func base64urlDecode(_ code: String) -> Data? {
        var base64 = code
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        base64 += String(repeating: "=", count: (4 - base64.count % 4) % 4)
        return Data(base64Encoded: base64)
    }

    static func huntAndSender(fromData sealed: Data) -> (Hunt, CrewCard?)? {
        guard let compressed = try? HuntCrypto.decrypt(sealed),
              let raw = try? (compressed as NSData).decompressed(using: .zlib) as Data else { return nil }

        var payloadData = raw
        var sender: CrewCard?
        // Current format: a signed envelope. Links shared before signing
        // existed carry a bare payload, and still open.
        if let envelope = try? JSONDecoder().decode(Envelope.self, from: raw) {
            payloadData = envelope.payload
            if let name = envelope.senderName,
               let keyData = envelope.senderKey,
               let signature = envelope.signature,
               let key = try? Curve25519.Signing.PublicKey(rawRepresentation: keyData),
               key.isValidSignature(signature, for: envelope.payload) {
                sender = CrewCard(name: name, publicKey: keyData)
            }
        }

        guard let payload = try? JSONDecoder().decode(Payload.self, from: payloadData) else { return nil }
        let hunt = Hunt(
            id: payload.id,
            name: payload.name,
            prize: payload.prize,
            points: payload.points,
            role: .received,
            createdAt: .now,
            sequential: payload.sequential ?? false,
            startsAt: payload.startsAt,
            endsAt: payload.endsAt
        )
        return (hunt, sender)
    }
}

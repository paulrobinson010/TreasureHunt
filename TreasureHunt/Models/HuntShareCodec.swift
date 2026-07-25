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
    static let webHost = "treasurehunt.robbo-online.uk"

    /// Only what the recipient needs — progress and role stay on each device.
    private struct Payload: Codable {
        var id: UUID
        var name: String
        var prize: String
        var points: [TreasurePoint]
    }

    /// A hunter's progress, sent back to the hunt maker (or a sibling's copy).
    struct ProgressReport: Codable {
        var huntID: UUID
        var name: String
        var foundPointIDs: Set<UUID>
    }

    /// Everything a shared link can contain.
    enum Decoded {
        case hunt(Hunt)
        case progress(ProgressReport)
    }

    // MARK: Encoding

    /// JSON → zlib compress → AES-GCM encrypt. The wire format for both links and files.
    static func sealedData(for hunt: Hunt) throws -> Data {
        let raw = try JSONEncoder().encode(
            Payload(id: hunt.id, name: hunt.name, prize: hunt.prize, points: hunt.points)
        )
        let compressed = try (raw as NSData).compressed(using: .zlib) as Data
        return try HuntCrypto.encrypt(compressed)
    }

    /// https://treasurehunt.robbo-online.uk/hunt/?d=<base64url sealed payload>
    static func url(for hunt: Hunt) throws -> URL {
        guard let url = URL(string: "https://\(webHost)/hunt/?d=\(base64url(try sealedData(for: hunt)))") else {
            throw CocoaError(.coderInvalidValue)
        }
        return url
    }

    /// https://treasurehunt.robbo-online.uk/progress/?p=<base64url sealed report>
    static func progressURL(for hunt: Hunt) throws -> URL {
        let raw = try JSONEncoder().encode(
            ProgressReport(huntID: hunt.id, name: hunt.name, foundPointIDs: hunt.foundPointIDs)
        )
        let compressed = try (raw as NSData).compressed(using: .zlib) as Data
        let sealed = try HuntCrypto.encrypt(compressed)
        guard let url = URL(string: "https://\(webHost)/progress/?p=\(base64url(sealed))") else {
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

    /// Routes any incoming link/file to what it contains: a hunt, or a
    /// progress report from a hunter.
    static func decode(url: URL) -> Decoded? {
        if url.scheme == "https" || url.scheme == "http",
           url.host?.lowercased() == webHost,
           url.pathComponents.count > 1, url.pathComponents[1] == "progress" {
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let code = components.queryItems?.first(where: { $0.name == "p" })?.value,
                  let report = progressReport(fromCode: code) else { return nil }
            return .progress(report)
        }
        return hunt(fromURL: url).map { .hunt($0) }
    }

    static func progressReport(fromCode code: String) -> ProgressReport? {
        guard let sealed = base64urlDecode(code),
              let compressed = try? HuntCrypto.decrypt(sealed),
              let raw = try? (compressed as NSData).decompressed(using: .zlib) as Data else { return nil }
        return try? JSONDecoder().decode(ProgressReport.self, from: raw)
    }

    /// Handles universal links, legacy treasurehunt:// links, and opened
    /// .treasurehunt files.
    static func hunt(fromURL url: URL) -> Hunt? {
        if url.isFileURL {
            let secured = url.startAccessingSecurityScopedResource()
            defer { if secured { url.stopAccessingSecurityScopedResource() } }
            guard let data = try? Data(contentsOf: url) else { return nil }
            return hunt(fromData: data)
        }
        if url.scheme == "https" || url.scheme == "http" {
            guard url.host?.lowercased() == webHost else { return nil }
            // https://host/hunt/?d=<code>
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let code = components.queryItems?.first(where: { $0.name == "d" })?.value {
                return hunt(fromCode: code)
            }
            // https://host/hunt/<code>
            if url.pathComponents.count > 2, url.pathComponents[1] == "hunt" {
                return hunt(fromCode: url.pathComponents[2])
            }
            return nil
        }
        guard url.scheme == scheme else { return nil }
        // treasurehunt://hunt/<code> — "hunt" is the host, the code is the path.
        let code = url.pathComponents.count > 1 ? url.pathComponents[1] : (url.host ?? "")
        return hunt(fromCode: code)
    }

    static func hunt(fromCode code: String) -> Hunt? {
        guard let sealed = base64urlDecode(code) else { return nil }
        return hunt(fromData: sealed)
    }

    private static func base64urlDecode(_ code: String) -> Data? {
        var base64 = code
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        base64 += String(repeating: "=", count: (4 - base64.count % 4) % 4)
        return Data(base64Encoded: base64)
    }

    static func hunt(fromData sealed: Data) -> Hunt? {
        guard let compressed = try? HuntCrypto.decrypt(sealed),
              let raw = try? (compressed as NSData).decompressed(using: .zlib) as Data,
              let payload = try? JSONDecoder().decode(Payload.self, from: raw) else { return nil }
        return Hunt(
            id: payload.id,
            name: payload.name,
            prize: payload.prize,
            points: payload.points,
            role: .received,
            createdAt: .now
        )
    }
}

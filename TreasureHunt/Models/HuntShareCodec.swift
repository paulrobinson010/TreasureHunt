import Foundation

/// Encodes a hunt into a link or file so it can be sent over iMessage/WhatsApp
/// with no server involved — the whole hunt travels inside the link/file.
enum HuntShareCodec {
    static let scheme = "treasurehunt"
    static let fileExtension = "treasurehunt"

    /// Only what the recipient needs — progress and role stay on each device.
    private struct Payload: Codable {
        var id: UUID
        var name: String
        var prize: String
        var points: [TreasurePoint]
    }

    // MARK: Encoding

    static func data(for hunt: Hunt) throws -> Data {
        try JSONEncoder().encode(Payload(id: hunt.id, name: hunt.name, prize: hunt.prize, points: hunt.points))
    }

    /// treasurehunt://hunt/<zlib-compressed, base64url payload>
    static func url(for hunt: Hunt) throws -> URL {
        let raw = try data(for: hunt)
        let compressed = try (raw as NSData).compressed(using: .zlib) as Data
        let code = compressed.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        guard let url = URL(string: "\(scheme)://hunt/\(code)") else {
            throw CocoaError(.coderInvalidValue)
        }
        return url
    }

    /// Writes a shareable .treasurehunt file to the temporary directory.
    static func exportFile(for hunt: Hunt) throws -> URL {
        let safeName = hunt.name.replacingOccurrences(of: "/", with: "-")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(safeName.isEmpty ? "Hunt" : safeName)
            .appendingPathExtension(fileExtension)
        try data(for: hunt).write(to: url, options: .atomic)
        return url
    }

    // MARK: Decoding

    /// Handles both treasurehunt:// links and opened .treasurehunt files.
    static func hunt(fromURL url: URL) -> Hunt? {
        if url.isFileURL {
            let secured = url.startAccessingSecurityScopedResource()
            defer { if secured { url.stopAccessingSecurityScopedResource() } }
            guard let data = try? Data(contentsOf: url) else { return nil }
            return hunt(fromData: data)
        }
        guard url.scheme == scheme else { return nil }
        // treasurehunt://hunt/<code> — "hunt" is the host, the code is the path.
        let code = url.pathComponents.count > 1 ? url.pathComponents[1] : (url.host ?? "")
        return hunt(fromCode: code)
    }

    static func hunt(fromCode code: String) -> Hunt? {
        var base64 = code
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        base64 += String(repeating: "=", count: (4 - base64.count % 4) % 4)
        guard let compressed = Data(base64Encoded: base64),
              let raw = try? (compressed as NSData).decompressed(using: .zlib) as Data else { return nil }
        return hunt(fromData: raw)
    }

    static func hunt(fromData data: Data) -> Hunt? {
        guard let payload = try? JSONDecoder().decode(Payload.self, from: data) else { return nil }
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

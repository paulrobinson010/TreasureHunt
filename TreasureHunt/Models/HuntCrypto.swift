import CryptoKit
import Foundation

/// Hash-key encryption for hunts in transit: a shared app secret is hashed
/// with SHA-256 to derive a stable AES-256 key, and payloads are sealed with
/// AES-GCM (fresh random nonce per hunt, tamper-authenticated).
///
/// The key lives inside the app, so this keeps hunts unreadable to messaging
/// servers, link previews and anyone snooping the link — it is transport
/// obfuscation between copies of this app, not end-to-end secrecy from
/// someone who reverse-engineers the binary.
enum HuntCrypto {
    private static let secret = "TreasureHunt.robbo-online.uk.v1"

    private static var key: SymmetricKey {
        SymmetricKey(data: SHA256.hash(data: Data(secret.utf8)))
    }

    static func encrypt(_ plaintext: Data) throws -> Data {
        let sealed = try AES.GCM.seal(plaintext, using: key)
        guard let combined = sealed.combined else {
            throw CocoaError(.coderInvalidValue)
        }
        return combined
    }

    static func decrypt(_ ciphertext: Data) throws -> Data {
        try AES.GCM.open(try AES.GCM.SealedBox(combined: ciphertext), using: key)
    }
}

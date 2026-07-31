import CryptoKit
import Foundation
import Security
import UIKit

/// This phone's hunting identity: a display name plus a signing key pair whose
/// private half never leaves the Keychain. Hunts are signed with it, so the
/// people you've shaken hands with can be told apart from everyone else.
enum HunterIdentity {
    private static let keychainTag = "uk.robbo-online.x-marks.hunterkey"
    private static let nameKey = "hunterName"

    /// What other hunters see. Editable; defaults to the device name.
    static var name: String {
        get {
            UserDefaults.standard.string(forKey: nameKey)
                ?? UIDevice.current.name
        }
        set {
            UserDefaults.standard.set(newValue.trimmingCharacters(in: .whitespaces), forKey: nameKey)
        }
    }

    static var publicKey: Curve25519.Signing.PublicKey {
        privateKey.publicKey
    }

    /// The card handed over during a handshake.
    static var card: CrewCard {
        CrewCard(name: name, publicKey: publicKey.rawRepresentation)
    }

    static func sign(_ data: Data) -> Data? {
        try? privateKey.signature(for: data)
    }

    // MARK: Keychain-backed key

    private static var cached: Curve25519.Signing.PrivateKey?

    private static var privateKey: Curve25519.Signing.PrivateKey {
        if let cached { return cached }
        if let stored = loadKey() {
            cached = stored
            return stored
        }
        let fresh = Curve25519.Signing.PrivateKey()
        saveKey(fresh)
        cached = fresh
        return fresh
    }

    private static func loadKey() -> Curve25519.Signing.PrivateKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainTag,
            kSecReturnData as String: true,
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return try? Curve25519.Signing.PrivateKey(rawRepresentation: data)
    }

    private static func saveKey(_ key: Curve25519.Signing.PrivateKey) {
        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainTag,
            kSecValueData as String: key.rawRepresentation,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]
        SecItemDelete(attributes as CFDictionary)
        SecItemAdd(attributes as CFDictionary, nil)
    }
}

/// A hunter's public identity, exchanged when two people join up.
struct CrewCard: Codable, Identifiable, Hashable {
    var name: String
    var publicKey: Data

    var id: Data { publicKey }

    var isMe: Bool { publicKey == HunterIdentity.publicKey.rawRepresentation }
}

/// Everyone allowed to send this phone treasure hunts.
@MainActor
final class CrewStore: ObservableObject {
    @Published private(set) var members: [CrewCard] = []

    private let fileURL: URL

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("crew.json")
        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode([CrewCard].self, from: data) {
            members = decoded
        }
    }

    func contains(publicKey: Data) -> Bool {
        members.contains { $0.publicKey == publicKey }
    }

    func member(publicKey: Data) -> CrewCard? {
        members.first { $0.publicKey == publicKey }
    }

    /// Adds or renames a crew member. Returns false if it was already there.
    @discardableResult
    func add(_ card: CrewCard) -> Bool {
        guard !card.isMe else { return false }
        if let index = members.firstIndex(where: { $0.publicKey == card.publicKey }) {
            members[index].name = card.name
            save()
            return false
        }
        members.append(card)
        save()
        return true
    }

    func remove(_ card: CrewCard) {
        members.removeAll { $0.publicKey == card.publicKey }
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(members) else { return }
        try? data.write(to: fileURL, options: [.atomic, .completeFileProtection])
    }
}

import CryptoKit
import Foundation
import Security

/// What this phone is allowed to do. Set once when the app is first opened,
/// and the single most important safety boundary in X-Marks: hunts point at
/// real places, so deciding *who* may send a child to one cannot rest on a
/// puzzle the child could solve, or on a prompt a stranger could talk them
/// through.
enum DeviceRole: String, Codable {
    /// Makes hunts, decides who's in the crew, and can hunt too.
    case grownUp
    /// Hunts only. Cannot create, cannot change the crew, and cannot accept
    /// a hunt from anyone the grown-up hasn't already added.
    case hunter

    var canCreateHunts: Bool { self == .grownUp }
    var canManageCrewUnaided: Bool { self == .grownUp }
}

enum DeviceSetup {
    private static let roleKey = "deviceRole"
    private static let passcodeTag = "uk.robbo-online.x-marks.parentpasscode"

    /// Nil until a grown-up has answered "who is this phone for?".
    static var role: DeviceRole? {
        guard let raw = UserDefaults.standard.string(forKey: roleKey) else { return nil }
        return DeviceRole(rawValue: raw)
    }

    static var isHunterPhone: Bool { role == .hunter }

    static func setRole(_ role: DeviceRole) {
        UserDefaults.standard.set(role.rawValue, forKey: roleKey)
    }

    /// Forget what this phone is, so setup runs again. Used when a grown-up
    /// hands their phone over to a hunter and needs to set a passcode.
    static func reset() {
        UserDefaults.standard.removeObject(forKey: roleKey)
        clearPasscode()
    }

    // MARK: Grown-up passcode

    /// On a hunter's phone, changing anything that matters needs the grown-up
    /// who set it up — not a sum, which the child might work out and a
    /// stranger could coach them through.
    static var hasPasscode: Bool { storedHash() != nil }

    static func setPasscode(_ code: String) {
        save(hash(code))
    }

    /// Wrong guesses cost time, escalating fast: four digits is only 10,000
    /// combinations and a bored child has all afternoon.
    private static let attemptsKey = "passcodeFailures"
    private static let lockUntilKey = "passcodeLockedUntil"

    static var lockedOutFor: TimeInterval {
        let until = UserDefaults.standard.double(forKey: lockUntilKey)
        return max(0, until - Date.now.timeIntervalSince1970)
    }

    static func verify(_ code: String) -> Bool {
        guard lockedOutFor <= 0, let stored = storedHash() else { return false }
        if stored == hash(code) {
            UserDefaults.standard.removeObject(forKey: attemptsKey)
            UserDefaults.standard.removeObject(forKey: lockUntilKey)
            return true
        }
        let failures = UserDefaults.standard.integer(forKey: attemptsKey) + 1
        UserDefaults.standard.set(failures, forKey: attemptsKey)
        if failures >= 3 {
            // 30 s, 60 s, 120 s… capped at ten minutes.
            let delay = min(30 * pow(2, Double(failures - 3)), 600)
            UserDefaults.standard.set(Date.now.timeIntervalSince1970 + delay, forKey: lockUntilKey)
        }
        return false
    }

    static func clearPasscode() {
        SecItemDelete([
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: passcodeTag,
        ] as CFDictionary)
    }

    private static func hash(_ code: String) -> Data {
        Data(SHA256.hash(data: Data(code.trimmingCharacters(in: .whitespaces).utf8)))
    }

    private static func storedHash() -> Data? {
        var item: CFTypeRef?
        let status = SecItemCopyMatching([
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: passcodeTag,
            kSecReturnData as String: true,
        ] as CFDictionary, &item)
        guard status == errSecSuccess else { return nil }
        return item as? Data
    }

    private static func save(_ digest: Data) {
        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: passcodeTag,
            kSecValueData as String: digest,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]
        SecItemDelete(attributes as CFDictionary)
        SecItemAdd(attributes as CFDictionary, nil)
    }
}

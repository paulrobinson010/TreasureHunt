import CloudKit
import CryptoKit
import Foundation

/// Automatic progress updates, CycleHUD-style: hunters publish their found
/// set to a CloudKit *public* database record named by an unguessable
/// per-hunt token, sealed with a per-hunt AES-GCM key that travels only
/// inside the hunt's encrypted share payload. iCloud (and therefore Apple,
/// and the developer) store nothing but ciphertext; no accounts are added —
/// writes ride on the device's own iCloud sign-in.
enum ProgressSync {
    private static let database =
        CKContainer(identifier: "iCloud.com.paulrobinson.TreasureHunt2").publicCloudDatabase

    /// One anonymous, stable id per device so each hunter has their own slot
    /// on the board.
    private static var hunterID: String {
        if let id = UserDefaults.standard.string(forKey: "hunterID") { return id }
        let id = UUID().uuidString
        UserDefaults.standard.set(id, forKey: "hunterID")
        return id
    }

    struct HunterProgress: Codable {
        var foundPointIDs: Set<UUID>
        var updatedAt: Date
    }

    /// hunterID → that hunter's progress.
    typealias Board = [String: HunterProgress]

    static func makeToken() -> String {
        let alphabet = Array("abcdefghjkmnpqrstuvwxyz23456789")
        return String((0..<12).map { _ in alphabet.randomElement()! })
    }

    /// Hunter side: merge my found set onto the shared board. Fire-and-forget
    /// with a bounded conflict retry; the manual progress links remain the
    /// fallback when iCloud isn't available.
    static func push(hunt: Hunt, attempt: Int = 0) {
        guard let token = hunt.syncToken, let keyData = hunt.syncKeyData, attempt <= 3 else { return }
        let key = SymmetricKey(data: keyData)
        let id = recordID(for: token)
        database.fetch(withRecordID: id) { existing, _ in
            let record = existing ?? CKRecord(recordType: "XMarksProgress", recordID: id)
            var board = decodeBoard(record, key: key) ?? [:]
            board[hunterID] = HunterProgress(foundPointIDs: hunt.foundPointIDs, updatedAt: .now)
            guard let sealed = seal(board, key: key) else { return }
            record["payload"] = sealed
            database.save(record) { _, error in
                if let ck = error as? CKError, ck.code == .serverRecordChanged {
                    push(hunt: hunt, attempt: attempt + 1)
                }
            }
        }
    }

    /// Maker side: everyone's finds, merged into one set. Completion on main.
    static func fetch(hunt: Hunt, completion: @escaping (Set<UUID>?) -> Void) {
        guard let token = hunt.syncToken, let keyData = hunt.syncKeyData else {
            completion(nil)
            return
        }
        let key = SymmetricKey(data: keyData)
        database.fetch(withRecordID: recordID(for: token)) { record, _ in
            let union = record.flatMap { decodeBoard($0, key: key) }
                .map { board in board.values.reduce(into: Set<UUID>()) { $0.formUnion($1.foundPointIDs) } }
            DispatchQueue.main.async { completion(union) }
        }
    }

    private static func recordID(for token: String) -> CKRecord.ID {
        CKRecord.ID(recordName: "xmarks-progress-\(token)")
    }

    private static func decodeBoard(_ record: CKRecord, key: SymmetricKey) -> Board? {
        guard let base64 = record["payload"] as? String,
              let sealed = Data(base64Encoded: base64),
              let box = try? AES.GCM.SealedBox(combined: sealed),
              let json = try? AES.GCM.open(box, using: key) else { return nil }
        return try? JSONDecoder().decode(Board.self, from: json)
    }

    private static func seal(_ board: Board, key: SymmetricKey) -> String? {
        guard let json = try? JSONEncoder().encode(board),
              let sealed = try? AES.GCM.seal(json, using: key).combined else { return nil }
        return sealed.base64EncodedString()
    }
}

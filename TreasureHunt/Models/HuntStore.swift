import Combine
import Foundation

@MainActor
final class HuntStore: ObservableObject {
    @Published private(set) var hunts: [Hunt] = []

    private let fileURL: URL

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("hunts.json")
        load()
    }

    func hunt(id: UUID) -> Hunt? {
        hunts.first { $0.id == id }
    }

    func add(_ hunt: Hunt) {
        hunts.insert(hunt, at: 0)
        save()
    }

    /// Adds a hunt that arrived via a link or file. Returns false if it was already imported.
    @discardableResult
    func importHunt(_ hunt: Hunt) -> Bool {
        guard !hunts.contains(where: { $0.id == hunt.id }) else { return false }
        hunts.insert(hunt, at: 0)
        save()
        return true
    }

    func delete(_ hunt: Hunt) {
        hunts.removeAll { $0.id == hunt.id }
        save()
    }

    /// Merges a hunter's progress report into any copy of that hunt on this
    /// phone. Returns the updated hunt, or nil if we don't have it.
    func applyProgress(_ report: HuntShareCodec.ProgressReport) -> Hunt? {
        guard let index = hunts.firstIndex(where: { $0.id == report.huntID }) else { return nil }
        hunts[index].foundPointIDs.formUnion(report.foundPointIDs)
        hunts[index].progressUpdatedAt = .now
        save()
        return hunts[index]
    }

    func markFound(_ point: TreasurePoint, in hunt: Hunt) {
        guard let index = hunts.firstIndex(where: { $0.id == hunt.id }) else { return }
        hunts[index].foundPointIDs.insert(point.id)
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([Hunt].self, from: data) else { return }
        hunts = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(hunts) else { return }
        // completeFileProtection keeps the store encrypted at rest until the
        // device is first unlocked.
        try? data.write(to: fileURL, options: [.atomic, .completeFileProtection])
    }
}

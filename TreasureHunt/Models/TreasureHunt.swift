import CoreLocation
import Foundation

struct TreasurePoint: Identifiable, Codable, Hashable {
    let id: UUID
    var latitude: Double
    var longitude: Double

    init(id: UUID = UUID(), coordinate: CLLocationCoordinate2D) {
        self.id = id
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Centre of the fuzzy circle shown to hunters. Deterministically offset from
    /// the real point (5–25 m, seeded by the point's id) so the circle's centre
    /// never gives the exact spot away, while the real point stays well inside
    /// the 50 m circle.
    var displayCenter: CLLocationCoordinate2D {
        let seed = id.uuid
        let angle = Double(seed.0) / 255 * 360
        let distance = 5 + Double(seed.1) / 255 * 20
        return GeoMath.offset(coordinate, distance: distance, bearing: angle)
    }

    /// A more heavily blurred centre (30–75 m off) used for the pre-hunt preview.
    var previewCenter: CLLocationCoordinate2D {
        let seed = id.uuid
        let angle = Double(seed.2) / 255 * 360
        let distance = 30 + Double(seed.3) / 255 * 45
        return GeoMath.offset(coordinate, distance: distance, bearing: angle)
    }
}

enum HuntRole: String, Codable {
    case created
    case received
}

struct Hunt: Identifiable, Codable {
    let id: UUID
    var name: String
    var prize: String
    var points: [TreasurePoint]
    var role: HuntRole
    var createdAt: Date
    var foundPointIDs: Set<UUID> = []

    var isSolved: Bool {
        !points.isEmpty && foundPointIDs.count == points.count
    }

    var unfoundPoints: [TreasurePoint] {
        points.filter { !foundPointIDs.contains($0.id) }
    }

    func isFound(_ point: TreasurePoint) -> Bool {
        foundPointIDs.contains(point.id)
    }

    func nearestUnfoundPoint(to coordinate: CLLocationCoordinate2D) -> TreasurePoint? {
        unfoundPoints.min {
            GeoMath.distance(from: coordinate, to: $0.coordinate) < GeoMath.distance(from: coordinate, to: $1.coordinate)
        }
    }
}

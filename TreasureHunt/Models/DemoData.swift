#if targetEnvironment(simulator)
import CoreLocation
import Foundation

/// Simulator-only screenshot fuel: three Central Park hunts in every state.
/// Compiled out of device builds entirely.
extension HuntStore {
    private static let demoNames = ["Central Park Treasure", "Playground Gold", "Saturday Adventure"]

    func loadDemoData() {
        // Reload cleanly on every tap.
        for hunt in hunts where Self.demoNames.contains(hunt.name) {
            delete(hunt)
        }

        // Mid-hunt: two of four famous spots found, two to go.
        let parkPoints = [
            TreasurePoint(coordinate: .init(latitude: 40.76593, longitude: -73.97106)), // Bethesda Fountain
            TreasurePoint(coordinate: .init(latitude: 40.77577, longitude: -73.97187)), // Bow Bridge
            TreasurePoint(coordinate: .init(latitude: 40.77939, longitude: -73.96920)), // Belvedere Castle
            TreasurePoint(coordinate: .init(latitude: 40.77459, longitude: -73.96654)), // Alice in Wonderland
        ]
        var centralPark = Hunt(
            id: UUID(),
            name: "Central Park Treasure",
            prize: "Winner picks the ice cream flavours! 🍦",
            points: parkPoints,
            role: .received,
            createdAt: .now.addingTimeInterval(-3600)
        )
        centralPark.foundPointIDs = [parkPoints[0].id, parkPoints[3].id]

        // Solved: ready to show the prize screen and confetti.
        let goldPoints = [
            TreasurePoint(coordinate: .init(latitude: 40.76785, longitude: -73.97183)),
            TreasurePoint(coordinate: .init(latitude: 40.76858, longitude: -73.97293)),
            TreasurePoint(coordinate: .init(latitude: 40.76932, longitude: -73.97101)),
        ]
        var playgroundGold = Hunt(
            id: UUID(),
            name: "Playground Gold",
            prize: "A trip to the toy shop! 🧸",
            points: goldPoints,
            role: .received,
            createdAt: .now.addingTimeInterval(-86400)
        )
        playgroundGold.foundPointIDs = Set(goldPoints.map(\.id))

        // Made by me, with a progress report arrived.
        let adventurePoints = [
            TreasurePoint(coordinate: .init(latitude: 40.77210, longitude: -73.97435)), // Strawberry Fields
            TreasurePoint(coordinate: .init(latitude: 40.77436, longitude: -73.97821)),
            TreasurePoint(coordinate: .init(latitude: 40.77693, longitude: -73.97656)),
        ]
        var saturday = Hunt(
            id: UUID(),
            name: "Saturday Adventure",
            prize: "Movie night + popcorn 🍿",
            points: adventurePoints,
            role: .created,
            createdAt: .now.addingTimeInterval(-7200)
        )
        saturday.foundPointIDs = [adventurePoints[0].id]
        saturday.progressUpdatedAt = .now.addingTimeInterval(-600)

        add(saturday)
        add(playgroundGold)
        add(centralPark)

        // A part-filled chest for the collection screenshot.
        if loot.isEmpty {
            let items: [(String, String, Double?)] = [
                ("💎", "Blue Diamond", 0),
                ("💎", "Ruby Red Gem", 160),
                ("💎", "Emerald Gem", -80),
                ("🦜", "Chatty Parrot", nil),
                ("👑", "Pirate Crown", nil),
            ]
            for (emoji, name, hue) in items {
                collect(LootItem(id: UUID(), emoji: emoji, name: name,
                                 huntName: "Playground Gold",
                                 date: .now.addingTimeInterval(-86400), hue: hue))
            }
        }
    }
}
#endif

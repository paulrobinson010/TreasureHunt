import MapKit
import SwiftUI

/// Map flavour shared by every map in the app, remembered across launches.
enum MapFlavor: String {
    case standard
    case satellite

    var style: MapStyle {
        switch self {
        case .standard: .standard
        case .satellite: .hybrid(elevation: .realistic)
        }
    }

    mutating func toggle() {
        self = self == .standard ? .satellite : .standard
    }
}

/// Floating button that flips between the drawn map and satellite imagery.
struct MapStyleButton: View {
    @Binding var flavor: MapFlavor

    var body: some View {
        Button {
            flavor.toggle()
        } label: {
            Image(systemName: flavor == .standard ? "globe.europe.africa.fill" : "map.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.brandCyan)
                .padding(10)
                .background(.ultraThinMaterial, in: Circle())
                .shadow(radius: 3)
        }
        .accessibilityLabel(flavor == .standard ? "Switch to satellite view" : "Switch to map view")
    }
}

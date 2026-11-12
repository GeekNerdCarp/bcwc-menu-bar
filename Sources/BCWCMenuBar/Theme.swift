import AppKit
import SwiftUI

// Look and feel borrowed from the site: sky photography behind frosted glass panels,
// one bright accent, and rounded numerals.
enum Theme {
    static let accent = Color(red: 0.39, green: 0.71, blue: 1.0)
    static let ok = Color(red: 0.19, green: 0.82, blue: 0.35)
    static let alert = Color(red: 1.0, green: 0.27, blue: 0.23)
    static let amber = Color(red: 1.0, green: 0.71, blue: 0.28)
    static let card = RoundedRectangle(cornerRadius: 16, style: .continuous)

    // Scene photo for the current condition, matching the site's sky photography.
    static func scene(code: Int?, isDay: Bool?) -> NSImage? {
        let day = isDay ?? true
        let family: String
        switch code ?? -1 {
        case 0, 1: family = "clear"
        case 2: family = "cloud"
        case 3: family = "overcast"
        case 45, 48: family = "fog"
        case 51...67, 80...82: family = "rain"
        case 71...77, 85, 86: family = "winter"
        case 95...99: family = "storm"
        default: family = "cloud"
        }
        let name = "\(family)-\(day ? "day" : "night")"
        guard let url = Bundle.main.url(forResource: name, withExtension: "jpg", subdirectory: "scenes") else { return nil }
        return NSImage(contentsOf: url)
    }
}

extension View {
    // Frosted glass panel with a hairline edge, as on the site's cards.
    func glassCard(padding: CGFloat = 12) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: Theme.card)
            .overlay(Theme.card.stroke(Color.white.opacity(0.12), lineWidth: 0.8))
    }
}

enum PanelTab: CaseIterable, Identifiable {
    case now, radar, stations, river

    var id: Self { self }

    var symbol: String {
        switch self {
        case .now: return "sun.max.fill"
        case .radar: return "dot.radiowaves.left.and.right"
        case .stations: return "binoculars.fill"
        case .river: return "water.waves"
        }
    }

    var label: String {
        switch self {
        case .now: return "Now"
        case .radar: return "Radar"
        case .stations: return "Stations"
        case .river: return "River"
        }
    }
}

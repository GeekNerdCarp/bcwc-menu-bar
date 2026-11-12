import Foundation

// Turns the site's weather codes and values into the icon, wording and numbers the panel shows.
enum Presentation {
    static let labels: [Int: String] = [
        0: "Clear sky", 1: "Mainly clear", 2: "Partly cloudy", 3: "Overcast",
        45: "Fog", 48: "Rime fog",
        51: "Light drizzle", 53: "Drizzle", 55: "Dense drizzle", 56: "Freezing drizzle", 57: "Dense freezing drizzle",
        61: "Light rain", 63: "Rain", 65: "Heavy rain", 66: "Freezing rain", 67: "Heavy freezing rain",
        71: "Light snow", 73: "Snow", 75: "Heavy snow", 77: "Snow grains",
        80: "Rain showers", 81: "Heavy rain showers", 82: "Violent showers",
        85: "Snow showers", 86: "Heavy snow showers",
        95: "Thunderstorm", 96: "Thunderstorm + hail", 99: "Severe thunderstorm + hail"
    ]

    // SF Symbols render as monochrome template images in the menu bar, as the menu bar requires.
    static func symbol(code: Int?, isDay: Bool?) -> String {
        let day = isDay ?? true
        switch code ?? -1 {
        case 0, 1: return day ? "sun.max.fill" : "moon.stars.fill"
        case 2: return day ? "cloud.sun.fill" : "cloud.moon.fill"
        case 3: return "cloud.fill"
        case 45, 48: return "cloud.fog.fill"
        case 51...57: return "cloud.drizzle.fill"
        case 61...67, 80...82: return "cloud.rain.fill"
        case 71...77, 85, 86: return "cloud.snow.fill"
        case 95...99: return "cloud.bolt.rain.fill"
        default: return "cloud.fill"
        }
    }

    static func label(_ code: Int?) -> String {
        guard let code else { return "Conditions unavailable" }
        return labels[code] ?? "Conditions"
    }

    static func degrees(_ value: Double?) -> String {
        guard let value else { return "--" }
        return "\(Int(value.rounded()))°"
    }

    static func number(_ value: Double?, _ suffix: String = "") -> String {
        guard let value else { return "--" }
        return "\(Int(value.rounded()))\(suffix)"
    }

    static func compass(_ degrees: Double?) -> String {
        guard let degrees else { return "--" }
        let points = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let index = Int((((degrees.truncatingRemainder(dividingBy: 360)) + 360).truncatingRemainder(dividingBy: 360) / 22.5).rounded()) % 16
        return points[index]
    }

    static func uv(_ value: Double?) -> String {
        guard let value else { return "--" }
        switch value {
        case ..<3: return "Low"
        case ..<6: return "Moderate"
        case ..<8: return "High"
        case ..<11: return "Very high"
        default: return "Extreme"
        }
    }

    static let isoFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    static let isoPlain = ISO8601DateFormatter()

    static func date(_ text: String?) -> Date? {
        guard let text else { return nil }
        return isoFractional.date(from: text) ?? isoPlain.date(from: text)
    }

    static let clock: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        f.timeZone = TimeZone(identifier: "America/New_York")
        return f
    }()

    static let hour: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "ha"
        f.timeZone = TimeZone(identifier: "America/New_York")
        return f
    }()

    static func clockText(_ text: String?) -> String {
        guard let d = date(text) else { return "--" }
        return clock.string(from: d) + " ET"
    }

    static func hourText(_ text: String?) -> String {
        guard let d = date(text) else { return "--" }
        return hour.string(from: d).lowercased()
    }

    static func daylight(sunrise: String?, sunset: String?) -> String {
        guard let a = date(sunrise), let b = date(sunset), b > a else { return "--" }
        let minutes = Int(b.timeIntervalSince(a) / 60)
        return "\(minutes / 60) hr \(minutes % 60) min"
    }
}

extension Presentation {
    static func trendSymbol(_ trend: String?) -> String {
        switch trend?.lowercased() {
        case "rising": return "arrow.up.right"
        case "falling": return "arrow.down.right"
        default: return "arrow.right"
        }
    }

    static func gaugeStage(_ value: Double?) -> String {
        guard let value else { return "--" }
        return String(format: "%.2f ft", value)
    }

    static func tone(_ name: String?) -> String {
        name?.lowercased() ?? "normal"
    }
}

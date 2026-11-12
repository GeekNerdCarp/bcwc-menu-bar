import Foundation

// Shapes of the public BCWC data endpoints (bcwc.cloud/api/...). Every field is optional
// so a partial response still renders what it has.

struct TownWeather: Decodable {
    let townName: String?
    let observedAt: String?
    let guidanceValidLabel: String?
    let temperatureF: Double?
    let apparentTemperatureF: Double?
    let temperatureMaxF: Double?
    let temperatureMinF: Double?
    let dewPointF: Double?
    let relativeHumidityPct: Double?
    let windMph: Double?
    let windGustMph: Double?
    let windDirDeg: Double?
    let weatherCode: Int?
    let pressureMslMb: Double?
    let uvIndexMax: Double?
    let sunrise: String?
    let sunset: String?
    let story: Story?
}

struct Story: Decodable {
    let hourly: [HourPoint]?
}

struct HourPoint: Decodable {
    let time: String?
    let temperatureF: Double?
    let precipitationProbabilityPct: Double?
    let weatherCode: Int?
    let isDay: Bool?
    let windMph: Double?
}

struct ForecastResponse: Decodable {
    let periods: [ForecastPeriod]?
}

struct ForecastPeriod: Decodable, Identifiable {
    let name: String
    let isDaytime: Bool
    let temperature: Double?
    let shortForecast: String?
    let detailedForecast: String?
    let precipChancePct: Double?

    var id: String { name + (shortForecast ?? "") }
}

struct AlertsResponse: Decodable {
    let alerts: [AlertItem]?
    let fetchedAt: String?
}

struct AlertItem: Decodable, Identifiable {
    let id: String
    let event: String
    let headline: String?
    let severity: String?
    let endsAt: String?
    let area: String?
}

struct RadarStatus: Decodable {
    let provider: String?
    let availability: String?
    let timingVerified: Bool?
    let frameTime: String?
}

// Everything the panel shows, gathered for one refresh.
struct Snapshot {
    var weather: TownWeather
    var forecast: [ForecastPeriod]
    var alerts: [AlertItem]
    var radar: RadarStatus?
    var fetchedAt: Date
}

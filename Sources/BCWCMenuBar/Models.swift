import Foundation

// Shapes of the public BCWC data endpoints (bcwc.cloud/api/...). Fields are optional so a
// partial response still renders what it has.

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

struct RadarFramesResponse: Decodable {
    let provider: String?
    let radar: RadarBlock?
    let frameTime: String?
}

struct RadarBlock: Decodable {
    let host: String?
    let past: [RadarFrame]?
}

struct RadarFrame: Decodable {
    let time: Double
    let path: String
}

struct SurfaceResponse: Decodable {
    let cards: [SurfaceCard]?
    let fetchedAt: String?
}

struct SurfaceCard: Decodable, Identifiable {
    let stationId: String
    let airportName: String?
    let distanceLabel: String?
    let temperatureF: Double?
    let dewPointF: Double?
    let skyCondition: String?
    let windLabel: String?
    let visibilityLabel: String?
    let relativeHumidityPct: Double?
    let ageLabel: String?
    let error: String?

    var id: String { stationId }
}

struct RiverResponse: Decodable {
    let gauges: [Gauge]?
    let fetchedAt: String?
}

struct Gauge: Decodable, Identifiable {
    let id: String
    let name: String
    let currentStageFt: Double?
    let currentDischargeCfs: Double?
    let trend: String?
    let trendDeltaFt: Double?
    let statusLabel: String?
    let statusTone: String?
    let observedAt: String?
    let thresholds: Thresholds?
    let forecastCrestFt: Double?
    let error: String?
}

struct Thresholds: Decodable {
    let actionFt: Double?
    let minorFt: Double?
    let moderateFt: Double?
    let majorFt: Double?
}

// Everything the panel shows, gathered for one refresh.
struct Snapshot {
    var weather: TownWeather
    var forecast: [ForecastPeriod]
    var alerts: [AlertItem]
    var radar: RadarStatus?
    var stations: [SurfaceCard]
    var rivers: [Gauge]
    var fetchedAt: Date
}

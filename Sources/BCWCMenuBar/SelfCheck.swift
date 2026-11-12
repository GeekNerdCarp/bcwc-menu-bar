import Foundation

// `BCWCMenuBar --check` fetches the live site once, prints what the panel would show, and exits.
enum SelfCheck {
    static func run() async -> Never {
        do {
            let s = try await BCWCClient.snapshot()
            let w = s.weather
            print("town: \(w.townName ?? "?") · \(Presentation.degrees(w.temperatureF)) · \(Presentation.label(w.weatherCode)) · icon \(Presentation.symbol(code: w.weatherCode, isDay: w.story?.hourly?.first?.isDay))")
            print("feels \(Presentation.degrees(w.apparentTemperatureF)) · H \(Presentation.degrees(w.temperatureMaxF)) L \(Presentation.degrees(w.temperatureMinF)) · humidity \(Presentation.number(w.relativeHumidityPct, "%"))")
            print("wind \(Presentation.compass(w.windDirDeg)) \(Presentation.number(w.windMph)) mph · pressure \(w.pressureMslMb.map { String(format: "%.2f inHg", $0 * 0.02953) } ?? "--")")
            print("hourly points: \(w.story?.hourly?.count ?? 0) · next hour \(Presentation.hourText(w.story?.hourly?.first?.time))")
            print("forecast periods: \(s.forecast.count) · first: \(s.forecast.first?.name ?? "none")")
            print("alerts: \(s.alerts.count)")
            print("radar: \(s.radar?.availability ?? "none") · \(s.radar?.provider ?? "none")")
            print("sunrise \(Presentation.clockText(w.sunrise)) · sunset \(Presentation.clockText(w.sunset)) · daylight \(Presentation.daylight(sunrise: w.sunrise, sunset: w.sunset))")
            exit(0)
        } catch {
            print("check failed: \(error)")
            exit(1)
        }
    }
}

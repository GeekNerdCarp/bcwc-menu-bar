import AppKit
import SwiftUI
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
            print("stations: \(s.stations.count) · \(s.stations.map { $0.stationId }.joined(separator: ", "))")
            print("rivers: \(s.rivers.count) · \(s.rivers.map { "\($0.name) \(Presentation.gaugeStage($0.currentStageFt))" }.joined(separator: " | "))")
            if let i = CommandLine.arguments.firstIndex(of: "--radar-png"), i + 1 < CommandLine.arguments.count {
                let meta = try await BCWCClient.fetch(RadarFramesResponse.self, "/api/radar-frames")
                if let host = meta.radar?.host, let last = meta.radar?.past?.last {
                    let base = try? await Basemap.snapshot()
                    let image = try await RadarRenderer.composite(host: host, path: last.path, basemap: base)
                    if let tiff = image.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff), let png = rep.representation(using: .png, properties: [:]) {
                        try png.write(to: URL(fileURLWithPath: CommandLine.arguments[i + 1]))
                        print("radar png written")
                    }
                }
            }
            if let i = CommandLine.arguments.firstIndex(of: "--panel-png"), i + 1 < CommandLine.arguments.count {
                let dir = CommandLine.arguments[i + 1]
                await MainActor.run {
                    let store = WeatherStore()
                    store.preview(s)
                    for tab in [PanelTab.now, .stations, .river] {
                        let renderer = ImageRenderer(content: PanelView(store: store, tab: tab))
                        renderer.scale = 2
                        if let cg = renderer.cgImage {
                            let rep = NSBitmapImageRep(cgImage: cg)
                            if let png = rep.representation(using: .png, properties: [:]) {
                                try? png.write(to: URL(fileURLWithPath: "\(dir)/panel-\(tab.label).png"))
                            }
                        }
                    }
                }
                print("panel pngs written")
            }
            exit(0)
        } catch {
            print("check failed: \(error)")
            exit(1)
        }
    }
}

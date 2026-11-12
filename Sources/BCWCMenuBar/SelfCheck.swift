import AppKit
import SwiftUI
import Foundation

// `BCWCMenuBar --check` fetches the live site once, prints what the panel would show, and exits.
enum SelfCheck {
    static func run() async -> Never {
        do {
            let s = try await BCWCClient.snapshot(town: Towns.defaultID)
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
                    if let base, let url = URL(string: "file://" + CommandLine.arguments[i + 1].replacingOccurrences(of: ".png", with: "-base.png")) {
                        let scale = RadarRenderer.scale
                        let (cx, cy) = RadarRenderer.worldPixel(lat: RadarRenderer.centerLat, lon: RadarRenderer.centerLon, zoom: Basemap.mapZoom)
                        let span = RadarRenderer.crop * pow(2.0, Double(Basemap.mapZoom - RadarRenderer.zoom))
                        let (mx, my) = RadarRenderer.worldPixel(lat: 39.0278, lon: -83.9191, zoom: Basemap.mapZoom)
                        let px = (mx - (cx - span / 2)) * Double(scale), py = (my - (cy - span / 2)) * Double(scale)
                        let marked = NSImage(size: base.size, flipped: true) { rect in
                            base.draw(in: rect)
                            NSColor.red.setFill()
                            NSBezierPath(ovalIn: NSRect(x: px - 4, y: py - 4, width: 8, height: 8)).fill()
                            return true
                        }
                        if let tiff = marked.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff), let png = rep.representation(using: .png, properties: [:]) {
                            try? png.write(to: url)
                        }
                    }
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

import SwiftUI

// What sits in the menu bar: one monochrome condition icon and the temperature.
struct MenuBarLabel: View {
    @ObservedObject var store: WeatherStore

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: store.symbol)
            Text(store.temperatureText).monospacedDigit()
        }
    }
}

// The panel that opens when the menu bar item is clicked.
struct PanelView: View {
    @ObservedObject var store: WeatherStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            if let snapshot = store.snapshot {
                alertCard(snapshot.alerts)
                hourlyStrip(snapshot.weather.story?.hourly ?? [])
                details(snapshot.weather)
                forecastList(snapshot.forecast)
                radarRow(snapshot.radar)
            } else {
                Text(store.errorMessage ?? "Loading the latest conditions…")
                    .foregroundStyle(.secondary)
            }
            Divider()
            footer
        }
        .padding(16)
        .frame(width: 360)
    }

    private var header: some View {
        let w = store.snapshot?.weather
        return HStack(alignment: .top, spacing: 12) {
            Image(systemName: store.symbol)
                .font(.system(size: 40))
                .symbolRenderingMode(.multicolor)
            VStack(alignment: .leading, spacing: 2) {
                Text(w?.townName ?? "Ripley").font(.headline)
                Text(store.temperatureText).font(.system(size: 40, weight: .light)).monospacedDigit()
                Text(Presentation.label(w?.weatherCode)).font(.subheadline)
                Text("Feels like \(Presentation.degrees(w?.apparentTemperatureF)) · H \(Presentation.degrees(w?.temperatureMaxF)) L \(Presentation.degrees(w?.temperatureMinF))")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }

    private func alertCard(_ alerts: [AlertItem]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if alerts.isEmpty {
                Label("No active NWS alerts", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(.green)
                    .font(.subheadline.weight(.semibold))
                Text("Brown County · checked \(Presentation.clockText(store.snapshot?.fetchedAt.ISO8601Format()))")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(alerts) { alert in
                    VStack(alignment: .leading, spacing: 2) {
                        Label(alert.event, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.subheadline.weight(.semibold))
                        if let headline = alert.headline {
                            Text(headline).font(.caption)
                        }
                        Text("Expires \(Presentation.clockText(alert.endsAt))")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
    }

    private func hourlyStrip(_ hours: [HourPoint]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Next 6 hours").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            HStack(spacing: 0) {
                ForEach(Array(hours.prefix(6).enumerated()), id: \.offset) { _, h in
                    VStack(spacing: 4) {
                        Text(Presentation.hourText(h.time)).font(.caption2).foregroundStyle(.secondary)
                        Image(systemName: Presentation.symbol(code: h.weatherCode, isDay: h.isDay))
                        Text(Presentation.degrees(h.temperatureF)).font(.caption).monospacedDigit()
                        Text("\(Presentation.number(h.precipitationProbabilityPct, "%"))")
                            .font(.caption2).foregroundStyle(.blue)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func details(_ w: TownWeather) -> some View {
        Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 8) {
            GridRow {
                stat("Humidity", Presentation.number(w.relativeHumidityPct, "%"))
                stat("Dew point", Presentation.degrees(w.dewPointF))
            }
            GridRow {
                stat("Wind", "\(Presentation.compass(w.windDirDeg)) \(Presentation.number(w.windMph)) mph")
                stat("Gusts", Presentation.number(w.windGustMph, " mph"))
            }
            GridRow {
                stat("Pressure", pressure(w.pressureMslMb))
                stat("UV", "\(Presentation.uv(w.uvIndexMax)) (\(Presentation.number(w.uvIndexMax)))")
            }
            GridRow {
                stat("Sunrise", Presentation.clockText(w.sunrise))
                stat("Sunset", Presentation.clockText(w.sunset))
            }
        }
    }

    private func pressure(_ mb: Double?) -> String {
        guard let mb else { return "--" }
        return String(format: "%.2f inHg", mb * 0.02953)
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.caption.weight(.medium)).monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func forecastList(_ periods: [ForecastPeriod]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("National Weather Service forecast").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            ForEach(Array(periods.prefix(6))) { p in
                HStack {
                    Text(p.name).font(.caption.weight(.medium)).frame(width: 84, alignment: .leading)
                    Text(p.shortForecast ?? "").font(.caption).lineLimit(1)
                    Spacer(minLength: 4)
                    Text("\(Presentation.degrees(p.temperature))")
                        .font(.caption.weight(.semibold)).monospacedDigit()
                }
            }
        }
    }

    private func radarRow(_ radar: RadarStatus?) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "dot.radiowaves.left.and.right")
            Text(radar?.availability == "available"
                 ? "Radar available · \(radar?.provider ?? "RainViewer")\(radar?.timingVerified == true ? " · frame time verified" : "")"
                 : "Radar status unavailable")
                .font(.caption)
        }
        .foregroundStyle(.secondary)
    }

    private var footer: some View {
        HStack {
            Text(store.errorMessage ?? "Updated \(Presentation.clockText(store.snapshot?.weather.observedAt))")
                .font(.caption2).foregroundStyle(.secondary).lineLimit(2)
            Spacer()
            Button {
                Task { await store.refresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .help("Refresh now")
            .disabled(store.isRefreshing)
            Link("bcwc.cloud", destination: URL(string: "https://www.bcwc.cloud")!)
                .font(.caption)
            Button("Quit") { NSApplication.shared.terminate(nil) }
                .font(.caption)
                .buttonStyle(.borderless)
        }
    }
}

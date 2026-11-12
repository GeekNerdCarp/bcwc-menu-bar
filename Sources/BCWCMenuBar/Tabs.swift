import SwiftUI

// Radar tab: a short loop over the county. Plays on request; nothing animates unless it is open.
struct RadarTab: View {
    @ObservedObject var radar: RadarLoader

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                if let image = radar.frames.indices.contains(radar.index) ? radar.frames[radar.index] : nil {
                    Image(nsImage: image)
                        .resizable()
                        .interpolation(.high)
                        .aspectRatio(1, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                } else if radar.isLoading {
                    ProgressView().controlSize(.regular)
                } else {
                    Text(radar.errorText ?? "Loading radar…")
                        .font(.system(size: 12, design: .rounded)).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(width: 320, height: 320)
            .background(Color(red: 0.02, green: 0.07, blue: 0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            HStack(spacing: 12) {
                Button { radar.togglePlay() } label: {
                    Image(systemName: radar.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(width: 30, height: 30)
                        .background(Theme.accent.opacity(0.2), in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(radar.frames.count < 2)
                .help(radar.isPlaying ? "Pause" : "Play")

                VStack(alignment: .leading, spacing: 2) {
                    Text(frameLabel)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                    Text("Radar © RainViewer · \(Basemap.attribution)")
                        .font(.system(size: 10, design: .rounded)).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .glassCard(padding: 10)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var frameLabel: String {
        guard radar.frameTimes.indices.contains(radar.index) else { return "Radar loads when opened" }
        return "Frame \(Presentation.clockText(ISO8601DateFormatter().string(from: radar.frameTimes[radar.index])))"
    }
}

// Stations tab: the three nearest NWS airport stations.
struct StationsTab: View {
    let cards: [SurfaceCard]

    var body: some View {
        VStack(spacing: 10) {
            if cards.isEmpty {
                Text("Station readings are unavailable right now.")
                    .font(.system(size: 12, design: .rounded)).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
            }
            ForEach(cards) { card in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(card.airportName ?? card.stationId)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .lineLimit(1)
                            Text("\(card.stationId) · \(card.distanceLabel ?? "")")
                                .font(.system(size: 10, design: .rounded)).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(card.ageLabel ?? "")
                            .font(.system(size: 10, design: .rounded)).foregroundStyle(.secondary)
                    }
                    HStack(alignment: .firstTextBaseline, spacing: 14) {
                        Text(Presentation.degrees(card.temperatureF))
                            .font(.system(size: 34, weight: .light, design: .rounded)).monospacedDigit()
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Dew \(Presentation.degrees(card.dewPointF))  ·  RH \(Presentation.number(card.relativeHumidityPct, "%"))")
                            Text(card.windLabel ?? "Wind --")
                            Text("Vis \(card.visibilityLabel ?? "--")")
                        }
                        .font(.system(size: 11, design: .rounded)).foregroundStyle(.secondary)
                    }
                    if let sky = card.skyCondition, !sky.isEmpty {
                        Text(sky).font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(Theme.accent)
                    }
                }
                .glassCard()
            }
            Text("Nearest ASOS/AWOS stations · NWS")
                .font(.system(size: 10, design: .rounded)).foregroundStyle(.secondary)
        }
    }
}

// River tab: stage, trend and where each gauge sits between its flood thresholds.
struct RiverTab: View {
    let gauges: [Gauge]

    var body: some View {
        VStack(spacing: 10) {
            if gauges.isEmpty {
                Text("River readings are unavailable right now.")
                    .font(.system(size: 12, design: .rounded)).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
            }
            ForEach(gauges) { g in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(g.name)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .lineLimit(1)
                        Spacer()
                        Text(g.statusLabel ?? "")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(toneColor(g.statusTone).opacity(0.18), in: Capsule())
                            .foregroundStyle(toneColor(g.statusTone))
                    }
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(Presentation.gaugeStage(g.currentStageFt))
                            .font(.system(size: 26, weight: .light, design: .rounded)).monospacedDigit()
                        Image(systemName: Presentation.trendSymbol(g.trend))
                            .foregroundStyle(Theme.accent)
                        Text(g.trend?.capitalized ?? "")
                            .font(.system(size: 11, design: .rounded)).foregroundStyle(.secondary)
                    }
                    thresholdBar(g)
                    if let crest = g.forecastCrestFt {
                        Text(String(format: "Forecast crest %.1f ft", crest))
                            .font(.system(size: 10, design: .rounded)).foregroundStyle(.secondary)
                    }
                }
                .glassCard()
            }
            Text("NOAA NWPS, with USGS fallback")
                .font(.system(size: 10, design: .rounded)).foregroundStyle(.secondary)
        }
    }

    // Stage on a bar running from zero to the major flood level, with action and flood marks.
    private func thresholdBar(_ g: Gauge) -> some View {
        let major = max(g.thresholds?.majorFt ?? 0, (g.currentStageFt ?? 0) + 1)
        let stage = max(0, g.currentStageFt ?? 0)
        return GeometryReader { geo in
            let w = geo.size.width
            ZStack(alignment: .leading) {
                Capsule().fill(.quaternary).frame(height: 6)
                Capsule().fill(Theme.accent).frame(width: w * min(1, stage / major), height: 6)
                ForEach([g.thresholds?.actionFt, g.thresholds?.minorFt, g.thresholds?.moderateFt].compactMap { $0 }, id: \.self) { mark in
                    Rectangle().fill(Theme.amber.opacity(0.8))
                        .frame(width: 1.5, height: 12)
                        .offset(x: w * min(1, mark / major))
                }
            }
        }
        .frame(height: 12)
    }

    private func toneColor(_ tone: String?) -> Color {
        switch Presentation.tone(tone) {
        case "normal": return Theme.ok
        case "action", "minor": return Theme.amber
        case "moderate", "major", "flood": return Theme.alert
        default: return .secondary
        }
    }
}

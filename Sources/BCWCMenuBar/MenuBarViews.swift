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

// The panel that opens from the menu bar: a sky header, four icon tabs, and the active tab.
struct PanelView: View {
    @ObservedObject var store: WeatherStore
    @StateObject private var radar = RadarLoader()
    @ObservedObject private var updater = AppUpdater.shared
    @State private var tab: PanelTab
    @State private var openAtLogin = LoginItem.isEnabled
    // The height of the tab area. Saved across launches; the grip at the bottom changes it.
    @AppStorage("panelContentHeight") private var contentHeight: Double = 430
    @State private var dragStartHeight: Double?

    init(store: WeatherStore, tab: PanelTab = .now) {
        self.store = store
        _tab = State(initialValue: tab)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            tabBar
            Divider().opacity(0.4)
            content
                .frame(height: CGFloat(contentHeight))
            Divider().opacity(0.4)
            footer
            versionRow
            resizeGrip
        }
        .frame(width: 380)
        .background(.regularMaterial)
        .onChange(of: tab) { newTab in
            if newTab != .radar { radar.stop() }
            if newTab == .radar { Task { await radar.loadIfNeeded() } }
        }
        .onDisappear { radar.stop() }
        .task { if tab == .radar { await radar.loadIfNeeded() } }
    }

    // MARK: Header

    private var header: some View {
        let w = store.snapshot?.weather
        return ZStack(alignment: .bottomLeading) {
            Group {
                if let image = Theme.scene(code: w?.weatherCode, isDay: store.isDay) {
                    Image(nsImage: image).resizable().scaledToFill()
                } else {
                    LinearGradient(colors: [Color(red: 0.12, green: 0.2, blue: 0.4), Color(red: 0.96, green: 0.65, blue: 0.08)],
                                   startPoint: .top, endPoint: .bottom)
                }
            }
            .frame(height: 150)
            .clipped()
            LinearGradient(colors: [.black.opacity(0.2), .black.opacity(0.78)], startPoint: .top, endPoint: .bottom)
            HStack(alignment: .bottom, spacing: 10) {
                VStack(alignment: .leading, spacing: 0) {
                    Menu {
                        ForEach(Towns.all) { town in
                            Button(town.name) { store.selectTown(town.id) }
                        }
                    } label: {
                        Text(((w?.townName ?? Towns.name(for: store.townID))).uppercased() + "  ⌄")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .tracking(1.2)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                    Text(store.temperatureText)
                        .font(.system(size: 60, weight: .ultraLight, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                    Text(Presentation.label(w?.weatherCode))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Feels \(Presentation.degrees(w?.apparentTemperatureF))  ·  H \(Presentation.degrees(w?.temperatureMaxF))  L \(Presentation.degrees(w?.temperatureMinF))")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                }
                Spacer(minLength: 0)
                Image(systemName: store.symbol)
                    .font(.system(size: 46))
                    .symbolRenderingMode(.multicolor)
                    .shadow(color: .black.opacity(0.3), radius: 6, y: 2)
            }
            .padding(16)
        }
        .frame(height: 150)
    }

    // MARK: Tabs

    private var tabBar: some View {
        HStack(spacing: 6) {
            ForEach(PanelTab.allCases) { t in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { tab = t }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: t.symbol)
                            .font(.system(size: 16, weight: .semibold))
                        Text(t.label)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .foregroundStyle(tab == t ? Theme.accent : .secondary)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(tab == t ? Theme.accent.opacity(0.16) : .clear)
                    )
                }
                .buttonStyle(.plain)
                .help(t.label)
                .accessibilityLabel(t.label)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: Content

    @ViewBuilder
    private var content: some View {
        switch tab {
        case .now:
            ScrollView {
                if let snapshot = store.snapshot {
                    VStack(spacing: 10) {
                        alertCard(snapshot.alerts)
                        hourlyStrip(snapshot.weather.story?.hourly ?? [])
                        details(snapshot.weather)
                        forecastList(snapshot.forecast)
                        radarRow(snapshot.radar)
                    }
                    .padding(12)
                } else {
                    Text(store.errorMessage ?? "Loading the latest conditions…")
                        .foregroundStyle(.secondary)
                        .padding(16)
                }
            }
        case .radar:
            RadarTab(radar: radar)
        case .stations:
            ScrollView { StationsTab(cards: store.snapshot?.stations ?? []).padding(12) }
        case .river:
            ScrollView { RiverTab(gauges: store.snapshot?.rivers ?? []).padding(12) }
        }
    }

    private func alertCard(_ alerts: [AlertItem]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if alerts.isEmpty {
                Label("No active NWS alerts", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(Theme.ok)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                Text("Brown County · \(Presentation.clockText(store.snapshot?.fetchedAt.ISO8601Format()))")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(alerts) { alert in
                    VStack(alignment: .leading, spacing: 2) {
                        Label(alert.event, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(Theme.alert)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                        if let headline = alert.headline { Text(headline).font(.caption) }
                        Text("Expires \(Presentation.clockText(alert.endsAt))").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .glassCard()
    }

    private func hourlyStrip(_ hours: [HourPoint]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("NEXT 6 HOURS").font(.system(size: 10, weight: .semibold, design: .rounded)).tracking(1).foregroundStyle(.secondary)
            HStack(spacing: 0) {
                ForEach(Array(hours.prefix(6).enumerated()), id: \.offset) { _, h in
                    VStack(spacing: 4) {
                        Text(Presentation.hourText(h.time)).font(.system(size: 10, design: .rounded)).foregroundStyle(.secondary)
                        Image(systemName: Presentation.symbol(code: h.weatherCode, isDay: h.isDay))
                            .symbolRenderingMode(.multicolor)
                            .font(.system(size: 15))
                        Text(Presentation.degrees(h.temperatureF)).font(.system(size: 12, weight: .medium, design: .rounded)).monospacedDigit()
                        Text(Presentation.number(h.precipitationProbabilityPct, "%"))
                            .font(.system(size: 10, design: .rounded)).foregroundStyle(Theme.accent)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .glassCard()
    }

    private func details(_ w: TownWeather) -> some View {
        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
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
                stat("UV", "\(Presentation.uv(w.uvIndexMax)) \(Presentation.number(w.uvIndexMax))")
            }
            GridRow {
                stat("Sunrise", Presentation.clockText(w.sunrise))
                stat("Sunset", Presentation.clockText(w.sunset))
            }
        }
        .glassCard()
    }

    private func pressure(_ mb: Double?) -> String {
        guard let mb else { return "--" }
        return String(format: "%.2f inHg", mb * 0.02953)
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label.uppercased()).font(.system(size: 9, weight: .semibold, design: .rounded)).tracking(0.8).foregroundStyle(.secondary)
            Text(value).font(.system(size: 13, weight: .medium, design: .rounded)).monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func forecastList(_ periods: [ForecastPeriod]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("NWS FORECAST").font(.system(size: 10, weight: .semibold, design: .rounded)).tracking(1).foregroundStyle(.secondary)
            ForEach(Array(periods.prefix(6))) { p in
                HStack {
                    Text(p.name).font(.system(size: 12, weight: .medium, design: .rounded)).frame(width: 88, alignment: .leading)
                    Text(p.shortForecast ?? "").font(.system(size: 12)).lineLimit(1)
                    Spacer(minLength: 4)
                    Text(Presentation.degrees(p.temperature))
                        .font(.system(size: 12, weight: .semibold, design: .rounded)).monospacedDigit()
                }
            }
        }
        .glassCard()
    }

    private func radarRow(_ radar: RadarStatus?) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "dot.radiowaves.left.and.right")
            Text(radar?.availability == "available"
                 ? "Radar · \(radar?.provider ?? "RainViewer")\(radar?.timingVerified == true ? " · frame time verified" : "")"
                 : "Radar status unavailable")
                .font(.system(size: 12, design: .rounded))
            Spacer(minLength: 0)
        }
        .foregroundStyle(.secondary)
        .glassCard(padding: 10)
    }

    // MARK: Resize

    // Drag the grip to make the tab area taller or shorter. Clamped so the panel stays usable.
    private var resizeGrip: some View {
        Capsule()
            .fill(.secondary.opacity(0.5))
            .frame(width: 44, height: 5)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
            .help("Drag to resize")
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let start = dragStartHeight ?? contentHeight
                        dragStartHeight = start
                        contentHeight = min(max(start + Double(value.translation.height), 300), 800)
                    }
                    .onEnded { _ in dragStartHeight = nil }
            )
    }

    // MARK: Version

    // Bottom line: the installed version, login-item toggle, and the update check.
    private var versionRow: some View {
        HStack(spacing: 8) {
            Text("BCWC Menu Bar \(AppUpdater.currentVersion)")
            Text("·")
            Toggle("Open at login", isOn: $openAtLogin)
                .toggleStyle(.checkbox)
                .onChange(of: openAtLogin) { on in LoginItem.set(on) }
            Spacer(minLength: 0)
            Button("Check for Updates…") { updater.checkForUpdates() }
                .buttonStyle(.borderless)
        }
        .font(.system(size: 10, design: .rounded))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 14)
        .padding(.bottom, 8)
    }

    // MARK: Footer

    private var footer: some View {
        HStack(spacing: 10) {
            Text(store.errorMessage ?? "Updated \(Presentation.clockText(store.snapshot?.weather.observedAt))")
                .font(.system(size: 10, design: .rounded)).foregroundStyle(.secondary).lineLimit(2)
            Spacer(minLength: 0)
            Button { Task { await store.refresh() } } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .help("Refresh now")
            .disabled(store.isRefreshing)
            Link("bcwc.cloud", destination: URL(string: "https://www.bcwc.cloud")!)
                .font(.system(size: 11, design: .rounded))
            Button("Quit") { NSApplication.shared.terminate(nil) }
                .font(.system(size: 11, design: .rounded))
                .buttonStyle(.borderless)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

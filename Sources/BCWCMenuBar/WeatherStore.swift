import Foundation

// Holds the latest snapshot and refreshes it on a steady schedule.
@MainActor
final class WeatherStore: ObservableObject {
    @Published private(set) var snapshot: Snapshot?
    @Published private(set) var errorMessage: String?
    @Published private(set) var isRefreshing = false

    private var loop: Task<Void, Never>?
    private var alertLoop: Task<Void, Never>?
    private let interval: UInt64 = 10 * 60 * 1_000_000_000
    // Alerts are one small request, so they are polled more often than the full snapshot.
    private let alertInterval: UInt64 = 2 * 60 * 1_000_000_000

    init() {
        loop = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                try? await Task.sleep(nanoseconds: self?.interval ?? 600_000_000_000)
            }
        }
        alertLoop = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refreshAlerts()
                try? await Task.sleep(nanoseconds: self?.alertInterval ?? 120_000_000_000)
            }
        }
    }

    func refreshAlerts() async {
        guard let alerts = try? await BCWCClient.alerts() else { return }
        AlertNotifier.shared.process(alerts)
        if var current = snapshot {
            current.alerts = alerts
            snapshot = current
        }
    }

    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            let latest = try await BCWCClient.snapshot()
            snapshot = latest
            AlertNotifier.shared.process(latest.alerts)
            errorMessage = nil
        } catch {
            // Keep the last good snapshot on screen and say the refresh failed.
            errorMessage = "Could not refresh. Showing the last update."
        }
    }

    // For previews and checks: show a snapshot without any network calls.
    func preview(_ value: Snapshot) {
        snapshot = value
    }

    var isDay: Bool? { snapshot?.weather.story?.hourly?.first?.isDay }
    var temperatureText: String { Presentation.degrees(snapshot?.weather.temperatureF) }
    var symbol: String { Presentation.symbol(code: snapshot?.weather.weatherCode, isDay: isDay) }
}

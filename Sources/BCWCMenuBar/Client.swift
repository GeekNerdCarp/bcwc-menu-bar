import Foundation

enum BCWCClient {
    static let base = URL(string: "https://www.bcwc.cloud")!
    static let town = "ripley"

    static func fetch<T: Decodable>(_ type: T.Type, _ path: String) async throws -> T {
        var request = URLRequest(url: URL(string: path, relativeTo: base)!)
        request.timeoutInterval = 25
        request.cachePolicy = .reloadIgnoringLocalCacheData
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    // The timed refresh: one request per endpoint, all in parallel.
    static func snapshot() async throws -> Snapshot {
        async let weather = fetch(TownWeather.self, "/api/weather?town=\(town)&include=story")
        async let forecast = fetch(ForecastResponse.self, "/api/nws-periods?town=\(town)")
        async let alerts = fetch(AlertsResponse.self, "/api/alerts")
        async let radar = try? fetch(RadarStatus.self, "/api/radar-frames")
        async let stations = try? fetch(SurfaceResponse.self, "/api/surface-observations")
        async let rivers = try? fetch(RiverResponse.self, "/api/river-conditions")
        return Snapshot(
            weather: try await weather,
            forecast: (try await forecast).periods ?? [],
            alerts: (try await alerts).alerts ?? [],
            radar: await radar,
            stations: (await stations)?.cards ?? [],
            rivers: (await rivers)?.gauges ?? [],
            fetchedAt: Date()
        )
    }
}

import AppKit
import Foundation

// Builds a small radar loop centred on Brown County from the RainViewer tiles the site uses.
// The loader only runs when the Radar tab is open, caches for five minutes, and stops when hidden.

// Street map under the radar: OpenStreetMap tiles, darkened to match the site. Fetched once per launch
// at zoom 9 over the same area as the radar crop, then scaled to the panel.
enum Basemap {
    static let mapZoom = 9
    static let attribution = "Map © OpenStreetMap contributors"

    static func snapshot() async throws -> NSImage {
        let scale = Double(RadarRenderer.size) / (RadarRenderer.crop * pow(2.0, Double(mapZoom - RadarRenderer.zoom)))
        let (cx, cy) = RadarRenderer.worldPixel(lat: RadarRenderer.centerLat, lon: RadarRenderer.centerLon, zoom: mapZoom)
        let span = RadarRenderer.crop * pow(2.0, Double(mapZoom - RadarRenderer.zoom))
        let ox = cx - span / 2, oy = cy - span / 2
        let minTx = Int(floor(ox / 256)), maxTx = Int(floor((ox + span - 1) / 256))
        let minTy = Int(floor(oy / 256)), maxTy = Int(floor((oy + span - 1) / 256))

        var tiles: [(x: Int, y: Int, image: NSImage)] = []
        try await withThrowingTaskGroup(of: (Int, Int, NSImage?).self) { group in
            for tx in minTx...maxTx {
                for ty in minTy...maxTy {
                    let url = URL(string: "https://tile.openstreetmap.org/\(mapZoom)/\(tx)/\(ty).png")!
                    group.addTask {
                        var request = URLRequest(url: url)
                        request.timeoutInterval = 20
                        request.setValue("BCWC-Menu-Bar/1.0 (macOS; +https://github.com/GeekNerdCarp/bcwc-menu-bar)", forHTTPHeaderField: "User-Agent")
                        let (data, _) = try await URLSession.shared.data(for: request)
                        return (tx, ty, NSImage(data: data))
                    }
                }
            }
            for try await (tx, ty, image) in group {
                if let image { tiles.append((tx, ty, image)) }
            }
        }

        let outSize = CGFloat(RadarRenderer.size)
        return NSImage(size: NSSize(width: outSize, height: outSize), flipped: true) { rect in
            NSColor(red: 0.02, green: 0.07, blue: 0.12, alpha: 1).setFill()
            rect.fill()
            for tile in tiles {
                let dest = NSRect(
                    x: (Double(tile.x) * 256 - ox) * scale,
                    y: (Double(tile.y) * 256 - oy) * scale,
                    width: 256 * scale, height: 256 * scale)
                tile.image.draw(in: dest, from: .zero, operation: .sourceOver, fraction: 1)
            }
            // Darken the light street map so the radar colours stand out, as on the site.
            NSColor(red: 0.03, green: 0.05, blue: 0.09, alpha: 0.42).setFill()
            rect.fill()
            return true
        }
    }
}

enum RadarRenderer {
    // RainViewer serves tiles up to zoom 7. The crop is taken at that zoom and scaled up to fill the panel.
    static let zoom = 7
    static let crop: Double = 96
    static let size: CGFloat = 320
    static var scale: CGFloat { size / CGFloat(crop) }

    static let centerLat = (CountyOutline.minLat + CountyOutline.maxLat) / 2
    static let centerLon = (CountyOutline.minLon + CountyOutline.maxLon) / 2

    static func worldPixel(lat: Double, lon: Double, zoom: Int) -> (Double, Double) {
        let n = pow(2.0, Double(zoom)) * 256
        let x = (lon + 180) / 360 * n
        let rad = lat * .pi / 180
        let y = (1 - log(tan(rad) + 1 / cos(rad)) / .pi) / 2 * n
        return (x, y)
    }

    static func tileURL(host: String, path: String, x: Int, y: Int) -> URL? {
        URL(string: "\(host)\(path)/256/\(zoom)/\(x)/\(y)/2/1_1.png")
    }

    static func composite(host: String, path: String, basemap: NSImage?) async throws -> NSImage {
        let (cx, cy) = worldPixel(lat: centerLat, lon: centerLon, zoom: zoom)
        let origin = (x: cx - crop / 2, y: cy - crop / 2)
        let minTx = Int(floor(origin.x / 256)), maxTx = Int(floor((origin.x + crop - 1) / 256))
        let minTy = Int(floor(origin.y / 256)), maxTy = Int(floor((origin.y + crop - 1) / 256))

        var tiles: [(x: Int, y: Int, image: NSImage)] = []
        try await withThrowingTaskGroup(of: (Int, Int, NSImage?).self) { group in
            for tx in minTx...maxTx {
                for ty in minTy...maxTy {
                    guard let url = tileURL(host: host, path: path, x: tx, y: ty) else { continue }
                    group.addTask {
                        var request = URLRequest(url: url)
                        request.timeoutInterval = 20
                        let (data, _) = try await URLSession.shared.data(for: request)
                        return (tx, ty, NSImage(data: data))
                    }
                }
            }
            for try await (tx, ty, image) in group {
                if let image { tiles.append((tx, ty, image)) }
            }
        }

        let outline = CountyOutline.latLon.map { lat, lon -> NSPoint in
            let (px, py) = worldPixel(lat: lat, lon: lon, zoom: zoom)
            return NSPoint(x: (px - origin.x) * scale, y: (py - origin.y) * scale)
        }
        let towns: [(String, Double, Double)] = [
            ("Ripley", 38.7459, -83.8444), ("Aberdeen", 38.6556, -83.7616), ("Georgetown", 38.8645, -83.9052),
            ("Mount Orab", 39.0278, -83.9191), ("Russellville", 38.8672729, -83.7877836), ("Sardinia", 39.0089, -83.7919)
        ]

        return NSImage(size: NSSize(width: size, height: size), flipped: true) { rect in
            NSColor(red: 0.02, green: 0.07, blue: 0.12, alpha: 1).setFill()
            rect.fill()
            basemap?.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1)
            for tile in tiles {
                let dest = NSRect(x: (Double(tile.x) * 256 - origin.x) * Double(scale), y: (Double(tile.y) * 256 - origin.y) * Double(scale), width: 256 * Double(scale), height: 256 * Double(scale))
                tile.image.draw(in: dest, from: .zero, operation: .sourceOver, fraction: 1)
            }
            if let first = outline.first {
                let path = NSBezierPath()
                path.move(to: first)
                for p in outline.dropFirst() { path.line(to: p) }
                path.close()
                NSColor.white.withAlphaComponent(0.85).setStroke()
                path.lineWidth = 1.2
                path.stroke()
            }
            for (name, lat, lon) in towns {
                let (px, py) = worldPixel(lat: lat, lon: lon, zoom: zoom)
                let p = NSPoint(x: (px - origin.x) * scale, y: (py - origin.y) * scale)
                let r: CGFloat = name == "Ripley" ? 5 : 3
                let dot = NSBezierPath(ovalIn: NSRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2))
                NSColor.white.withAlphaComponent(name == "Ripley" ? 1 : 0.8).setFill()
                dot.fill()
            }
            return true
        }
    }
}

@MainActor
final class RadarLoader: ObservableObject {
    @Published private(set) var frames: [NSImage] = []
    @Published private(set) var frameTimes: [Date] = []
    @Published var index = 0
    @Published private(set) var isPlaying = false
    @Published private(set) var isLoading = false
    @Published private(set) var errorText: String?

    private var loadedAt: Date?
    private var basemap: NSImage?
    private var playTask: Task<Void, Never>?
    private let maxAge: TimeInterval = 300
    private let frameCount = 6

    func loadIfNeeded() async {
        if let loadedAt, !frames.isEmpty, Date().timeIntervalSince(loadedAt) < maxAge { return }
        await load()
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let meta = try await BCWCClient.fetch(RadarFramesResponse.self, "/api/radar-frames")
            guard let host = meta.radar?.host, let past = meta.radar?.past, !past.isEmpty else {
                errorText = "Radar frames are unavailable right now."
                return
            }
            if basemap == nil { basemap = try? await Basemap.snapshot() }
            var images: [NSImage] = []
            var times: [Date] = []
            for frame in past.suffix(frameCount) {
                images.append(try await RadarRenderer.composite(host: host, path: frame.path, basemap: basemap))
                times.append(Date(timeIntervalSince1970: frame.time))
            }
            frames = images
            frameTimes = times
            index = max(0, images.count - 1)
            loadedAt = Date()
            errorText = nil
        } catch {
            errorText = "Radar could not load. Try again."
        }
    }

    func togglePlay() {
        isPlaying ? stop() : play()
    }

    func play() {
        guard frames.count > 1, !isPlaying else { return }
        isPlaying = true
        playTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 700_000_000)
                guard let self, self.isPlaying, !self.frames.isEmpty else { break }
                self.index = (self.index + 1) % self.frames.count
            }
        }
    }

    func stop() {
        isPlaying = false
        playTask?.cancel()
        playTask = nil
    }
}

import Foundation

// Checks the public GitHub releases for a newer version. One request at launch, then once a day.
@MainActor
final class UpdateChecker: ObservableObject {
    static let shared = UpdateChecker()

    @Published private(set) var latestVersion: String?
    @Published private(set) var releaseURL: URL?

    static let currentVersion: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev"

    private let latestAPI = URL(string: "https://api.github.com/repos/GeekNerdCarp/bcwc-menu-bar/releases/latest")!
    private var loop: Task<Void, Never>?

    var updateAvailable: Bool {
        guard let latestVersion else { return false }
        return Self.isNewer(latestVersion, than: Self.currentVersion)
    }

    func start() {
        guard loop == nil, Bundle.main.bundleIdentifier != nil else { return }
        loop = Task { [weak self] in
            while !Task.isCancelled {
                await self?.check()
                try? await Task.sleep(nanoseconds: 24 * 60 * 60 * 1_000_000_000)
            }
        }
    }

    func check() async {
        var request = URLRequest(url: latestAPI)
        request.timeoutInterval = 15
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("BCWC-Menu-Bar/\(Self.currentVersion)", forHTTPHeaderField: "User-Agent")
        guard let pair = try? await URLSession.shared.data(for: request) else { return }
        let (data, response) = pair
        guard let http = response as? HTTPURLResponse, http.statusCode == 200,
              let release = try? JSONDecoder().decode(Release.self, from: data) else { return }
        latestVersion = release.tagName.hasPrefix("v") ? String(release.tagName.dropFirst()) : release.tagName
        releaseURL = URL(string: release.htmlURL)
    }

    // Compares dotted numeric versions such as "1.10" and "1.9".
    static func isNewer(_ candidate: String, than current: String) -> Bool {
        let a = candidate.split(separator: ".").map { Int($0) ?? 0 }
        let b = current.split(separator: ".").map { Int($0) ?? 0 }
        for i in 0..<max(a.count, b.count) {
            let x = i < a.count ? a[i] : 0
            let y = i < b.count ? b[i] : 0
            if x != y { return x > y }
        }
        return false
    }

    private struct Release: Decodable {
        let tagName: String
        let htmlURL: String

        enum CodingKeys: String, CodingKey {
            case tagName = "tag_name"
            case htmlURL = "html_url"
        }
    }
}

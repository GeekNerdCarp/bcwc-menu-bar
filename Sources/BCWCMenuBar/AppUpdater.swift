import Sparkle
import SwiftUI

// Automatic updates through Sparkle. Checks the appcast daily and installs when the user agrees.
@MainActor
final class AppUpdater: ObservableObject {
    static let shared = AppUpdater()

    static let currentVersion: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev"

    private let controller = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)

    func checkForUpdates() {
        controller.checkForUpdates(nil)
    }
}

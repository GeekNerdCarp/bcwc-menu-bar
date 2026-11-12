import SwiftUI

@main
struct BCWCMenuBarApp: App {
    @StateObject private var store = WeatherStore()

    init() {
        if CommandLine.arguments.contains("--check") {
            Task { await SelfCheck.run() }
        }
    }

    var body: some Scene {
        MenuBarExtra {
            PanelView(store: store)
        } label: {
            MenuBarLabel(store: store)
        }
        .menuBarExtraStyle(.window)
    }
}

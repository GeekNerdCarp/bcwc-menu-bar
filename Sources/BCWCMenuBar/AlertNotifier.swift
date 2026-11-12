import Foundation
import UserNotifications

// Posts a macOS notification for each alert the site's alert list shows for the first time.
// The seen IDs are kept in UserDefaults so a relaunch does not repeat alerts already announced.
@MainActor
final class AlertNotifier {
    static let shared = AlertNotifier()

    private let defaultsKey = "seenAlertIDs"
    private let maxRemembered = 300
    private var didRequestPermission = false

    // Notifications need a real app bundle; the command-line checks have none.
    private var isAvailable: Bool { Bundle.main.bundleIdentifier != nil }

    func process(_ alerts: [AlertItem]) {
        guard isAvailable else { return }
        requestPermissionIfNeeded()

        var seen = UserDefaults.standard.stringArray(forKey: defaultsKey) ?? []
        let seenSet = Set(seen)
        let isFirstRun = !UserDefaults.standard.bool(forKey: "alertNotifierPrimed")

        for alert in alerts where !seenSet.contains(alert.id) {
            // On first run, remember what is already active without announcing it.
            if !isFirstRun { post(alert) }
            seen.append(alert.id)
        }

        UserDefaults.standard.set(Array(seen.suffix(maxRemembered)), forKey: defaultsKey)
        UserDefaults.standard.set(true, forKey: "alertNotifierPrimed")
    }

    private func requestPermissionIfNeeded() {
        guard !didRequestPermission else { return }
        didRequestPermission = true
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func post(_ alert: AlertItem) {
        let content = UNMutableNotificationContent()
        content.title = alert.event
        content.body = alert.headline ?? alert.area ?? "New NWS alert for Brown County"
        content.sound = .default

        // The alert ID is unique per issuance, so each alert gets its own notification.
        let request = UNNotificationRequest(identifier: alert.id, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}

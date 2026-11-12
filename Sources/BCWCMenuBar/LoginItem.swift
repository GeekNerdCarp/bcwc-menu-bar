import ServiceManagement

// Start-at-login through the system's login items (macOS 13 and later).
enum LoginItem {
    static var isEnabled: Bool { SMAppService.mainApp.status == .enabled }

    static func set(_ on: Bool) {
        do {
            if on { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
        } catch {
            // Usually means the app is not in /Applications. The toggle reverts on next open.
        }
    }
}

import Foundation

// The Brown County towns the site has forecasts for. The ids match the site's town list.
struct Town: Identifiable, Hashable {
    let id: String
    let name: String
}

enum Towns {
    static let all: [Town] = [
        Town(id: "aberdeen", name: "Aberdeen"),
        Town(id: "georgetown", name: "Georgetown"),
        Town(id: "mount-orab", name: "Mount Orab"),
        Town(id: "ripley", name: "Ripley"),
        Town(id: "russellville", name: "Russellville"),
        Town(id: "sardinia", name: "Sardinia"),
    ]

    static let defaultID = "ripley"

    static func name(for id: String) -> String {
        all.first { $0.id == id }?.name ?? "Ripley"
    }

    // Falls back to Ripley if a saved id is no longer in the list.
    static func validID(_ id: String?) -> String {
        guard let id, all.contains(where: { $0.id == id }) else { return defaultID }
        return id
    }
}

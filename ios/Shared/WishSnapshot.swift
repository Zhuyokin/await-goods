import Foundation

struct WishSnapshot: Codable, Hashable, Identifiable {
    let id: UUID
    let title: String
    let price: Double?
    let waitUntil: Date?
    let sortIndex: Int
}

struct WidgetSnapshotPayload: Codable {
    let updatedAt: Date
    let items: [WishSnapshot]
}

enum SharedAppGroup {
    static let identifier = "group.com.awaitgoods"
}

enum WidgetSnapshotStore {
    private static let key = "awaitGoods.widgetSnapshot"

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: SharedAppGroup.identifier) ?? .standard
    }

    static func save(items: [WishSnapshot]) {
        let payload = WidgetSnapshotPayload(updatedAt: Date(), items: items)
        guard let data = try? JSONEncoder().encode(payload) else { return }
        defaults.set(data, forKey: key)
    }

    static func load() -> [WishSnapshot] {
        guard let data = defaults.data(forKey: key),
              let payload = try? JSONDecoder().decode(WidgetSnapshotPayload.self, from: data) else {
            return []
        }
        return payload.items
    }
}

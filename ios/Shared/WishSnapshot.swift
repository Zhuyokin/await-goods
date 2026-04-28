import Foundation

struct WishSnapshot: Codable, Hashable, Identifiable {
    let id: UUID
    let title: String
    let price: Double?
    let savedAmount: Double
    let sortIndex: Int

    init(id: UUID, title: String, price: Double?, savedAmount: Double = 0, sortIndex: Int) {
        self.id = id
        self.title = title
        self.price = price
        self.savedAmount = savedAmount
        self.sortIndex = sortIndex
    }

    var savingsProgress: Double {
        guard let price, price > 0 else { return 0 }
        return min(max(savedAmount, 0) / price, 1)
    }

    var remainingAmount: Double? {
        guard let price, price > 0 else { return nil }
        return max(price - max(savedAmount, 0), 0)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case price
        case savedAmount
        case sortIndex
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        price = try container.decodeIfPresent(Double.self, forKey: .price)
        savedAmount = try container.decodeIfPresent(Double.self, forKey: .savedAmount) ?? 0
        sortIndex = try container.decode(Int.self, forKey: .sortIndex)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(price, forKey: .price)
        try container.encode(savedAmount, forKey: .savedAmount)
        try container.encode(sortIndex, forKey: .sortIndex)
    }
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

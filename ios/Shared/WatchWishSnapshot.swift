import Foundation

enum WatchWishStatus: String, Codable, CaseIterable, Identifiable {
    case waiting
    case bought
    case released

    var id: String { rawValue }

    var title: String {
        switch self {
        case .waiting: return "想买"
        case .bought: return "已拥有"
        case .released: return "放下"
        }
    }

    var iconName: String {
        switch self {
        case .waiting: return "heart"
        case .bought: return "checkmark"
        case .released: return "xmark"
        }
    }
}

struct WatchWishSnapshot: Codable, Hashable, Identifiable {
    let id: UUID
    let title: String
    let category: String
    let price: Double?
    let savedAmount: Double
    let priorityRawValue: Int
    let sortIndex: Int
    var statusRawValue: String
    var updatedAt: Date
    let currencyCode: String

    init(
        id: UUID,
        title: String,
        category: String,
        price: Double?,
        savedAmount: Double,
        priorityRawValue: Int,
        sortIndex: Int,
        statusRawValue: String,
        updatedAt: Date,
        currencyCode: String = "USD"
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.price = price
        self.savedAmount = savedAmount
        self.priorityRawValue = priorityRawValue
        self.sortIndex = sortIndex
        self.statusRawValue = statusRawValue
        self.updatedAt = updatedAt
        self.currencyCode = currencyCode
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, category, price, savedAmount, priorityRawValue, sortIndex
        case statusRawValue, updatedAt, currencyCode
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        category = try container.decode(String.self, forKey: .category)
        price = try container.decodeIfPresent(Double.self, forKey: .price)
        savedAmount = try container.decode(Double.self, forKey: .savedAmount)
        priorityRawValue = try container.decode(Int.self, forKey: .priorityRawValue)
        sortIndex = try container.decode(Int.self, forKey: .sortIndex)
        statusRawValue = try container.decode(String.self, forKey: .statusRawValue)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        currencyCode = try container.decodeIfPresent(String.self, forKey: .currencyCode) ?? "USD"
    }

    var status: WatchWishStatus {
        get { WatchWishStatus(rawValue: statusRawValue) ?? .waiting }
        set {
            statusRawValue = newValue.rawValue
            updatedAt = Date()
        }
    }

    var savingsProgress: Double {
        guard let price, price > 0 else { return 0 }
        return min(max(savedAmount, 0) / price, 1)
    }
}

struct WatchWishPayload: Codable {
    let updatedAt: Date
    let items: [WatchWishSnapshot]
    let currencyCode: String

    init(updatedAt: Date, items: [WatchWishSnapshot], currencyCode: String = "USD") {
        self.updatedAt = updatedAt
        self.items = items
        self.currencyCode = currencyCode
    }

    private enum CodingKeys: String, CodingKey {
        case updatedAt, items, currencyCode
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        items = try container.decode([WatchWishSnapshot].self, forKey: .items)
        currencyCode = try container.decodeIfPresent(String.self, forKey: .currencyCode) ?? "USD"
    }
}

enum WatchSyncMessageKey {
    static let payload = "awaitGoods.watch.payload"
    static let kind = "kind"
    static let requestSync = "requestSync"
    static let updateStatus = "updateStatus"
    static let itemID = "itemID"
    static let status = "status"
}

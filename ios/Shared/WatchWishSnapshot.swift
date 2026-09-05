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
}

enum WatchSyncMessageKey {
    static let payload = "awaitGoods.watch.payload"
    static let kind = "kind"
    static let requestSync = "requestSync"
    static let updateStatus = "updateStatus"
    static let itemID = "itemID"
    static let status = "status"
}

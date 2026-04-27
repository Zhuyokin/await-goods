import Foundation

enum WishItemStatus: String, Codable, CaseIterable, Identifiable {
    case waiting
    case bought
    case released
    case paused

    var id: String { rawValue }

    var title: String {
        switch self {
        case .waiting: return "想买"
        case .bought: return "已买"
        case .released: return "不买"
        case .paused: return "再想想"
        }
    }

    var iconName: String {
        switch self {
        case .waiting: return "heart"
        case .bought: return "checkmark"
        case .released: return "xmark"
        case .paused: return "pause"
        }
    }
}

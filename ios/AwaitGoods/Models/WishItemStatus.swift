import Foundation

enum WishItemStatus: String, Codable, CaseIterable, Identifiable {
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

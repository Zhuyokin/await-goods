import Foundation

enum WishItemStatus: String, Codable, CaseIterable, Identifiable {
    case waiting
    case bought
    case released
    case paused

    var id: String { rawValue }

    var title: String {
        switch self {
        case .waiting: return "候着"
        case .bought: return "已入手"
        case .released: return "已放下"
        case .paused: return "搁置"
        }
    }
}

import Foundation

enum MarkColor: String, Codable, CaseIterable, Identifiable {
    case none
    case green
    case yellow
    case pink
    case gray

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none: return "无"
        case .green: return "绿色"
        case .yellow: return "黄色"
        case .pink: return "粉色"
        case .gray: return "灰色"
        }
    }
}

import Foundation

enum DefaultWaitPeriod: Int, CaseIterable, Identifiable {
    case none = 0
    case three = 3
    case seven = 7
    case fourteen = 14
    case thirty = 30

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .none: return "无"
        default: return "\(rawValue) 天"
        }
    }
}

enum WaitPeriodSelection: Int, CaseIterable, Identifiable {
    case none = 0
    case three = 3
    case seven = 7
    case fourteen = 14
    case thirty = 30
    case custom = -1

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .none: return "无"
        case .custom: return "自定义"
        default: return "\(rawValue) 天"
        }
    }
}

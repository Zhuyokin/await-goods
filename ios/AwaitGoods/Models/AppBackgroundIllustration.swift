enum AppBackgroundIllustration: String, CaseIterable, Identifiable {
    static let storageKey = "backgroundIllustration"

    case sakura
    case willow

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sakura: return "樱花"
        case .willow: return "柳枝"
        }
    }

    var assetName: String {
        switch self {
        case .sakura: return "SakuraBranches"
        case .willow: return "WillowBranches"
        }
    }
}

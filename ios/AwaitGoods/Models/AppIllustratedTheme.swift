import Foundation

enum AppIllustratedTheme: String, CaseIterable, Identifiable {
    static let storageKey = "backgroundIllustration"

    case sakura
    case willow

    var id: String { rawValue }

    static var current: AppIllustratedTheme {
        AppIllustratedTheme(rawValue: UserDefaults.standard.string(forKey: storageKey) ?? "") ?? .sakura
    }

    var title: String {
        switch self {
        case .sakura: return "樱雨春笺"
        case .willow: return "柳影清风"
        }
    }

    var topAssetName: String {
        switch self {
        case .sakura: return "SakuraBranches"
        case .willow: return "WillowBranches"
        }
    }

    var bottomAssetName: String {
        switch self {
        case .sakura: return "SakuraForeground"
        case .willow: return "WillowForeground"
        }
    }

    var emptyStateAssetName: String {
        switch self {
        case .sakura: return "SakuraWishJar"
        case .willow: return "WillowWishJar"
        }
    }

    var colorTheme: AppTheme {
        switch self {
        case .sakura: return .berryGarden
        case .willow: return .springPaper
        }
    }
}

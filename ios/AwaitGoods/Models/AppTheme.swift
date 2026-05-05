import Foundation
import SwiftUI

typealias ThemeRGB = (CGFloat, CGFloat, CGFloat)

struct AdaptiveThemeColor {
    let light: ThemeRGB
    let dark: ThemeRGB
}

struct AppThemePalette {
    let pageBackground: AdaptiveThemeColor
    let listBackground: AdaptiveThemeColor
    let cardBackground: AdaptiveThemeColor
    let fieldBackground: AdaptiveThemeColor
    let primaryText: AdaptiveThemeColor
    let secondaryText: AdaptiveThemeColor
    let tertiaryText: AdaptiveThemeColor
    let separator: AdaptiveThemeColor
    let cardBorder: AdaptiveThemeColor
    let mint: AdaptiveThemeColor
    let freshGreen: AdaptiveThemeColor
    let softWood: AdaptiveThemeColor
    let softBlueGray: AdaptiveThemeColor
    let cream: AdaptiveThemeColor
    let apricot: AdaptiveThemeColor
    let blossom: AdaptiveThemeColor
    let skyWash: AdaptiveThemeColor
    let linkBlue: AdaptiveThemeColor
    let dangerRed: AdaptiveThemeColor
    let markGreen: AdaptiveThemeColor
    let markYellow: AdaptiveThemeColor
    let markPink: AdaptiveThemeColor
    let markGray: AdaptiveThemeColor
    let shadowLight: ThemeRGB
}

enum AppTheme: String, CaseIterable, Identifiable {
    static let storageKey = "appTheme"

    case springPaper
    case seaSalt
    case berryGarden
    case forestNight
    case apricotTea

    var id: String { rawValue }

    static var current: AppTheme {
        AppTheme(rawValue: UserDefaults.standard.string(forKey: storageKey) ?? "") ?? .springPaper
    }

    var title: String {
        switch self {
        case .springPaper: return "春日纸笺"
        case .seaSalt: return "海盐蓝调"
        case .berryGarden: return "暮莓花园"
        case .forestNight: return "墨绿静夜"
        case .apricotTea: return "杏茶暖光"
        }
    }

    var subtitle: String {
        switch self {
        case .springPaper: return "清爽绿意与纸张质感"
        case .seaSalt: return "蓝绿底色配一点珊瑚"
        case .berryGarden: return "莓果、鼠尾草和纸白"
        case .forestNight: return "深绿与温润木色"
        case .apricotTea: return "杏色、茶棕和蓝灰"
        }
    }

    var icon: String {
        switch self {
        case .springPaper: return "leaf"
        case .seaSalt: return "water.waves"
        case .berryGarden: return "camera.macro"
        case .forestNight: return "moon.stars"
        case .apricotTea: return "sun.max"
        }
    }

    var swatchColors: [Color] {
        [palette.freshGreen.light, palette.softWood.light, palette.softBlueGray.light].map { rgb in
            Color(red: rgb.0, green: rgb.1, blue: rgb.2)
        }
    }

    var previewBackground: Color {
        let rgb = palette.pageBackground.light
        return Color(red: rgb.0, green: rgb.1, blue: rgb.2)
    }

    var palette: AppThemePalette {
        switch self {
        case .springPaper:
            return Self.springPaperPalette
        case .seaSalt:
            return Self.seaSaltPalette
        case .berryGarden:
            return Self.berryGardenPalette
        case .forestNight:
            return Self.forestNightPalette
        case .apricotTea:
            return Self.apricotTeaPalette
        }
    }
}

private extension AppTheme {
    static func c(_ light: ThemeRGB, _ dark: ThemeRGB) -> AdaptiveThemeColor {
        AdaptiveThemeColor(light: light, dark: dark)
    }

    static let springPaperPalette = AppThemePalette(
        pageBackground: c((0.972, 0.982, 0.968), (0.105, 0.112, 0.108)),
        listBackground: c((0.992, 0.994, 0.988), (0.132, 0.138, 0.132)),
        cardBackground: c((1.000, 1.000, 0.996), (0.168, 0.176, 0.166)),
        fieldBackground: c((0.936, 0.958, 0.938), (0.214, 0.232, 0.214)),
        primaryText: c((0.120, 0.142, 0.132), (0.930, 0.948, 0.922)),
        secondaryText: c((0.380, 0.430, 0.395), (0.700, 0.744, 0.690)),
        tertiaryText: c((0.580, 0.628, 0.590), (0.555, 0.600, 0.558)),
        separator: c((0.812, 0.864, 0.812), (0.282, 0.320, 0.292)),
        cardBorder: c((0.800, 0.852, 0.802), (0.328, 0.365, 0.330)),
        mint: c((0.780, 0.882, 0.780), (0.430, 0.575, 0.435)),
        freshGreen: c((0.290, 0.520, 0.370), (0.610, 0.780, 0.610)),
        softWood: c((0.700, 0.570, 0.520), (0.695, 0.515, 0.490)),
        softBlueGray: c((0.380, 0.550, 0.610), (0.570, 0.720, 0.760)),
        cream: c((0.962, 0.976, 0.954), (0.156, 0.168, 0.152)),
        apricot: c((0.800, 0.580, 0.460), (0.725, 0.510, 0.410)),
        blossom: c((0.780, 0.560, 0.620), (0.745, 0.465, 0.540)),
        skyWash: c((0.928, 0.972, 0.982), (0.112, 0.142, 0.148)),
        linkBlue: c((0.300, 0.445, 0.520), (0.565, 0.720, 0.785)),
        dangerRed: c((0.675, 0.285, 0.255), (0.840, 0.470, 0.430)),
        markGreen: c((0.700, 0.835, 0.680), (0.500, 0.635, 0.450)),
        markYellow: c((0.925, 0.820, 0.585), (0.670, 0.575, 0.385)),
        markPink: c((0.940, 0.760, 0.780), (0.695, 0.470, 0.520)),
        markGray: c((0.740, 0.765, 0.720), (0.445, 0.470, 0.430)),
        shadowLight: (0.180, 0.150, 0.105)
    )

    static let seaSaltPalette = AppThemePalette(
        pageBackground: c((0.948, 0.978, 0.982), (0.085, 0.110, 0.118)),
        listBackground: c((0.985, 0.994, 0.994), (0.112, 0.138, 0.146)),
        cardBackground: c((0.998, 1.000, 0.996), (0.152, 0.178, 0.182)),
        fieldBackground: c((0.902, 0.952, 0.956), (0.190, 0.234, 0.238)),
        primaryText: c((0.104, 0.138, 0.148), (0.918, 0.954, 0.952)),
        secondaryText: c((0.330, 0.458, 0.484), (0.690, 0.786, 0.794)),
        tertiaryText: c((0.548, 0.650, 0.662), (0.520, 0.625, 0.635)),
        separator: c((0.740, 0.850, 0.858), (0.258, 0.330, 0.338)),
        cardBorder: c((0.708, 0.828, 0.836), (0.310, 0.392, 0.402)),
        mint: c((0.690, 0.858, 0.820), (0.320, 0.515, 0.488)),
        freshGreen: c((0.150, 0.488, 0.510), (0.560, 0.790, 0.790)),
        softWood: c((0.815, 0.520, 0.430), (0.790, 0.498, 0.420)),
        softBlueGray: c((0.250, 0.475, 0.650), (0.566, 0.725, 0.840)),
        cream: c((0.930, 0.972, 0.970), (0.125, 0.158, 0.162)),
        apricot: c((0.846, 0.580, 0.470), (0.800, 0.528, 0.442)),
        blossom: c((0.760, 0.550, 0.640), (0.724, 0.470, 0.580)),
        skyWash: c((0.890, 0.956, 0.986), (0.095, 0.150, 0.172)),
        linkBlue: c((0.205, 0.405, 0.615), (0.570, 0.748, 0.870)),
        dangerRed: c((0.685, 0.275, 0.245), (0.842, 0.465, 0.430)),
        markGreen: c((0.620, 0.820, 0.754), (0.420, 0.635, 0.570)),
        markYellow: c((0.908, 0.796, 0.520), (0.675, 0.585, 0.380)),
        markPink: c((0.932, 0.735, 0.740), (0.700, 0.470, 0.510)),
        markGray: c((0.710, 0.780, 0.792), (0.430, 0.502, 0.512)),
        shadowLight: (0.090, 0.190, 0.210)
    )

    static let berryGardenPalette = AppThemePalette(
        pageBackground: c((0.988, 0.964, 0.972), (0.118, 0.092, 0.108)),
        listBackground: c((0.998, 0.988, 0.990), (0.148, 0.120, 0.135)),
        cardBackground: c((1.000, 0.996, 0.992), (0.182, 0.150, 0.166)),
        fieldBackground: c((0.962, 0.914, 0.932), (0.236, 0.188, 0.212)),
        primaryText: c((0.160, 0.112, 0.126), (0.954, 0.928, 0.936)),
        secondaryText: c((0.465, 0.360, 0.390), (0.782, 0.700, 0.725)),
        tertiaryText: c((0.660, 0.552, 0.588), (0.625, 0.540, 0.565)),
        separator: c((0.880, 0.792, 0.816), (0.345, 0.278, 0.302)),
        cardBorder: c((0.856, 0.750, 0.784), (0.414, 0.330, 0.360)),
        mint: c((0.790, 0.868, 0.744), (0.420, 0.525, 0.382)),
        freshGreen: c((0.470, 0.575, 0.398), (0.690, 0.790, 0.615)),
        softWood: c((0.725, 0.455, 0.552), (0.782, 0.500, 0.606)),
        softBlueGray: c((0.505, 0.560, 0.665), (0.665, 0.710, 0.806)),
        cream: c((0.990, 0.952, 0.962), (0.160, 0.128, 0.144)),
        apricot: c((0.832, 0.612, 0.486), (0.778, 0.544, 0.438)),
        blossom: c((0.724, 0.390, 0.520), (0.800, 0.468, 0.610)),
        skyWash: c((0.940, 0.955, 0.982), (0.122, 0.142, 0.176)),
        linkBlue: c((0.445, 0.440, 0.650), (0.660, 0.670, 0.856)),
        dangerRed: c((0.690, 0.270, 0.270), (0.850, 0.462, 0.452)),
        markGreen: c((0.715, 0.820, 0.655), (0.500, 0.620, 0.450)),
        markYellow: c((0.910, 0.805, 0.570), (0.680, 0.585, 0.392)),
        markPink: c((0.930, 0.710, 0.792), (0.710, 0.470, 0.565)),
        markGray: c((0.760, 0.735, 0.750), (0.470, 0.440, 0.458)),
        shadowLight: (0.260, 0.110, 0.140)
    )

    static let forestNightPalette = AppThemePalette(
        pageBackground: c((0.948, 0.970, 0.934), (0.060, 0.082, 0.072)),
        listBackground: c((0.984, 0.990, 0.972), (0.090, 0.120, 0.105)),
        cardBackground: c((0.998, 0.996, 0.986), (0.132, 0.162, 0.142)),
        fieldBackground: c((0.900, 0.940, 0.875), (0.170, 0.214, 0.188)),
        primaryText: c((0.096, 0.135, 0.110), (0.920, 0.950, 0.920)),
        secondaryText: c((0.335, 0.430, 0.345), (0.690, 0.755, 0.695)),
        tertiaryText: c((0.548, 0.622, 0.545), (0.520, 0.585, 0.528)),
        separator: c((0.765, 0.842, 0.742), (0.245, 0.315, 0.278)),
        cardBorder: c((0.736, 0.825, 0.705), (0.302, 0.386, 0.340)),
        mint: c((0.718, 0.840, 0.650), (0.330, 0.520, 0.392)),
        freshGreen: c((0.215, 0.458, 0.318), (0.560, 0.765, 0.560)),
        softWood: c((0.680, 0.520, 0.365), (0.746, 0.552, 0.390)),
        softBlueGray: c((0.355, 0.540, 0.552), (0.560, 0.710, 0.720)),
        cream: c((0.945, 0.966, 0.928), (0.105, 0.135, 0.116)),
        apricot: c((0.792, 0.592, 0.405), (0.735, 0.540, 0.370)),
        blossom: c((0.700, 0.520, 0.585), (0.730, 0.470, 0.545)),
        skyWash: c((0.900, 0.955, 0.948), (0.076, 0.120, 0.126)),
        linkBlue: c((0.275, 0.455, 0.510), (0.545, 0.710, 0.760)),
        dangerRed: c((0.660, 0.285, 0.250), (0.840, 0.460, 0.410)),
        markGreen: c((0.645, 0.812, 0.604), (0.420, 0.612, 0.410)),
        markYellow: c((0.900, 0.790, 0.512), (0.660, 0.560, 0.355)),
        markPink: c((0.900, 0.730, 0.762), (0.685, 0.458, 0.508)),
        markGray: c((0.715, 0.750, 0.700), (0.426, 0.465, 0.420)),
        shadowLight: (0.120, 0.150, 0.095)
    )

    static let apricotTeaPalette = AppThemePalette(
        pageBackground: c((0.988, 0.968, 0.940), (0.120, 0.096, 0.082)),
        listBackground: c((0.998, 0.988, 0.970), (0.150, 0.122, 0.105)),
        cardBackground: c((1.000, 0.996, 0.986), (0.184, 0.150, 0.128)),
        fieldBackground: c((0.965, 0.928, 0.875), (0.235, 0.190, 0.160)),
        primaryText: c((0.158, 0.124, 0.100), (0.954, 0.928, 0.902)),
        secondaryText: c((0.485, 0.382, 0.305), (0.790, 0.708, 0.640)),
        tertiaryText: c((0.672, 0.560, 0.455), (0.635, 0.548, 0.478)),
        separator: c((0.880, 0.805, 0.706), (0.350, 0.288, 0.240)),
        cardBorder: c((0.855, 0.770, 0.660), (0.418, 0.340, 0.285)),
        mint: c((0.770, 0.835, 0.692), (0.405, 0.505, 0.360)),
        freshGreen: c((0.405, 0.510, 0.335), (0.665, 0.760, 0.560)),
        softWood: c((0.835, 0.535, 0.350), (0.805, 0.540, 0.375)),
        softBlueGray: c((0.420, 0.560, 0.628), (0.635, 0.748, 0.810)),
        cream: c((0.990, 0.958, 0.912), (0.158, 0.124, 0.105)),
        apricot: c((0.882, 0.600, 0.382), (0.820, 0.545, 0.365)),
        blossom: c((0.790, 0.535, 0.540), (0.760, 0.470, 0.510)),
        skyWash: c((0.920, 0.962, 0.972), (0.108, 0.140, 0.148)),
        linkBlue: c((0.330, 0.466, 0.570), (0.594, 0.728, 0.805)),
        dangerRed: c((0.675, 0.285, 0.250), (0.842, 0.465, 0.420)),
        markGreen: c((0.700, 0.808, 0.625), (0.488, 0.608, 0.420)),
        markYellow: c((0.925, 0.805, 0.520), (0.685, 0.578, 0.350)),
        markPink: c((0.930, 0.725, 0.735), (0.705, 0.455, 0.492)),
        markGray: c((0.758, 0.735, 0.695), (0.462, 0.438, 0.405)),
        shadowLight: (0.250, 0.150, 0.080)
    )
}
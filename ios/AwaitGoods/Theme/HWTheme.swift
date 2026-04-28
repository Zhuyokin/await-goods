import SwiftUI
import UIKit

enum HWTheme {
    private typealias RGB = (CGFloat, CGFloat, CGFloat)

    private static func adaptive(light: RGB, dark: RGB, alpha: CGFloat = 1) -> Color {
        Color(UIColor { traits in
            let value = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: value.0, green: value.1, blue: value.2, alpha: alpha)
        })
    }

    static let pageBackground = adaptive(light: (0.972, 0.982, 0.968), dark: (0.105, 0.112, 0.108))
    static let listBackground = adaptive(light: (0.992, 0.994, 0.988), dark: (0.132, 0.138, 0.132))
    static let cardBackground = adaptive(light: (1.000, 1.000, 0.996), dark: (0.168, 0.176, 0.166))
    static let fieldBackground = adaptive(light: (0.936, 0.958, 0.938), dark: (0.214, 0.232, 0.214))

    static let primaryText = adaptive(light: (0.120, 0.142, 0.132), dark: (0.930, 0.948, 0.922))
    static let secondaryText = adaptive(light: (0.380, 0.430, 0.395), dark: (0.700, 0.744, 0.690))
    static let tertiaryText = adaptive(light: (0.580, 0.628, 0.590), dark: (0.555, 0.600, 0.558))
    static let separator = adaptive(light: (0.812, 0.864, 0.812), dark: (0.282, 0.320, 0.292))
    static let cardBorder = adaptive(light: (0.800, 0.852, 0.802), dark: (0.328, 0.365, 0.330))

    static let mint = adaptive(light: (0.780, 0.882, 0.780), dark: (0.430, 0.575, 0.435))
    static let freshGreen = adaptive(light: (0.290, 0.520, 0.370), dark: (0.610, 0.780, 0.610))
    static let softWood = adaptive(light: (0.700, 0.570, 0.520), dark: (0.695, 0.515, 0.490))
    static let softBlueGray = adaptive(light: (0.380, 0.550, 0.610), dark: (0.570, 0.720, 0.760))
    static let cream = adaptive(light: (0.962, 0.976, 0.954), dark: (0.156, 0.168, 0.152))
    static let apricot = adaptive(light: (0.800, 0.580, 0.460), dark: (0.725, 0.510, 0.410))
    static let blossom = adaptive(light: (0.780, 0.560, 0.620), dark: (0.745, 0.465, 0.540))
    static let skyWash = adaptive(light: (0.928, 0.972, 0.982), dark: (0.112, 0.142, 0.148))

    static let linkBlue = adaptive(light: (0.300, 0.445, 0.520), dark: (0.565, 0.720, 0.785))
    static let dangerRed = adaptive(light: (0.675, 0.285, 0.255), dark: (0.840, 0.470, 0.430))
    static let softShadow = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.black.withAlphaComponent(0.28)
            : UIColor(red: 0.180, green: 0.150, blue: 0.105, alpha: 0.08)
    })

    static let weChatGreen = freshGreen
    static let sky = softBlueGray
    static let butter = softWood
    static let matcha = mint
    static let lavender = softBlueGray
    static let leafGreen = freshGreen

    static func markColor(_ markColor: MarkColor) -> Color {
        switch markColor {
        case .none: return fieldBackground
        case .green: return adaptive(light: (0.700, 0.835, 0.680), dark: (0.500, 0.635, 0.450))
        case .yellow: return adaptive(light: (0.925, 0.820, 0.585), dark: (0.670, 0.575, 0.385))
        case .pink: return adaptive(light: (0.940, 0.760, 0.780), dark: (0.695, 0.470, 0.520))
        case .gray: return adaptive(light: (0.740, 0.765, 0.720), dark: (0.445, 0.470, 0.430))
        }
    }
}


struct HWSpringBackdrop: View {
    var body: some View {
        HWTheme.pageBackground.ignoresSafeArea()
    }
}

struct HWCreamLeafBackdrop: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [HWTheme.listBackground, HWTheme.pageBackground, HWTheme.skyWash.opacity(0.56)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 18) {
                    ForEach(0..<18, id: \.self) { index in
                        Rectangle()
                            .fill(index.isMultiple(of: 3) ? HWTheme.separator.opacity(0.14) : HWTheme.separator.opacity(0.07))
                            .frame(height: 0.6)
                    }
                }
                .padding(.horizontal, 22)
                .position(x: proxy.size.width / 2, y: proxy.size.height * 0.42)

                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(HWTheme.fieldBackground.opacity(0.42))
                    .frame(width: proxy.size.width * 0.62, height: 54)
                    .rotationEffect(.degrees(-8))
                    .position(x: proxy.size.width * 0.22, y: 88)

                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .stroke(HWTheme.softBlueGray.opacity(0.20), lineWidth: 1)
                    .frame(width: 154, height: 104)
                    .rotationEffect(.degrees(5))
                    .position(x: proxy.size.width - 40, y: proxy.size.height * 0.28)

                Rectangle()
                    .fill(HWTheme.freshGreen.opacity(0.10))
                    .frame(width: 2, height: proxy.size.height * 0.54)
                    .position(x: proxy.size.width - 28, y: proxy.size.height * 0.70)

                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(HWTheme.softWood.opacity(0.12))
                    .frame(width: proxy.size.width * 0.52, height: 38)
                    .rotationEffect(.degrees(7))
                    .position(x: proxy.size.width * 0.78, y: proxy.size.height - 62)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

extension View {
    func softCard() -> some View {
        self
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(HWTheme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(HWTheme.cardBorder.opacity(0.68), lineWidth: 0.8)
            )
            .shadow(color: HWTheme.softShadow, radius: 3, x: 0, y: 1)
    }
}
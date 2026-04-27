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

    static let pageBackground = adaptive(light: (0.965, 0.956, 0.930), dark: (0.105, 0.102, 0.094))
    static let listBackground = adaptive(light: (0.982, 0.977, 0.960), dark: (0.132, 0.126, 0.116))
    static let cardBackground = adaptive(light: (1.000, 0.998, 0.990), dark: (0.172, 0.162, 0.148))
    static let fieldBackground = adaptive(light: (0.935, 0.923, 0.895), dark: (0.224, 0.210, 0.190))

    static let primaryText = adaptive(light: (0.145, 0.140, 0.125), dark: (0.930, 0.908, 0.870))
    static let secondaryText = adaptive(light: (0.420, 0.395, 0.350), dark: (0.705, 0.675, 0.625))
    static let tertiaryText = adaptive(light: (0.590, 0.555, 0.495), dark: (0.560, 0.530, 0.485))
    static let separator = adaptive(light: (0.858, 0.832, 0.775), dark: (0.292, 0.270, 0.235))
    static let cardBorder = adaptive(light: (0.842, 0.812, 0.752), dark: (0.338, 0.310, 0.268))

    static let mint = adaptive(light: (0.790, 0.835, 0.765), dark: (0.455, 0.560, 0.435))
    static let freshGreen = adaptive(light: (0.360, 0.475, 0.365), dark: (0.620, 0.735, 0.590))
    static let softWood = adaptive(light: (0.675, 0.610, 0.505), dark: (0.640, 0.555, 0.430))
    static let softBlueGray = adaptive(light: (0.420, 0.530, 0.555), dark: (0.570, 0.680, 0.705))
    static let cream = adaptive(light: (0.947, 0.929, 0.890), dark: (0.158, 0.148, 0.132))
    static let apricot = adaptive(light: (0.770, 0.585, 0.385), dark: (0.725, 0.520, 0.335))
    static let blossom = adaptive(light: (0.720, 0.545, 0.515), dark: (0.720, 0.455, 0.420))
    static let skyWash = adaptive(light: (0.925, 0.944, 0.936), dark: (0.118, 0.138, 0.136))

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
        case .green: return adaptive(light: (0.740, 0.812, 0.650), dark: (0.500, 0.615, 0.410))
        case .yellow: return adaptive(light: (0.920, 0.780, 0.535), dark: (0.670, 0.555, 0.355))
        case .pink: return adaptive(light: (0.930, 0.745, 0.680), dark: (0.675, 0.460, 0.430))
        case .gray: return adaptive(light: (0.765, 0.710, 0.650), dark: (0.470, 0.430, 0.380))
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
import SwiftUI
import UIKit

enum HWTheme {
    private static var palette: AppThemePalette { AppTheme.current.palette }

    private static func adaptive(_ color: AdaptiveThemeColor, alpha: CGFloat = 1) -> Color {
        Color(UIColor { traits in
            let value = traits.userInterfaceStyle == .dark ? color.dark : color.light
            return UIColor(red: value.0, green: value.1, blue: value.2, alpha: alpha)
        })
    }

    static var pageBackground: Color { adaptive(palette.pageBackground) }
    static var listBackground: Color { adaptive(palette.listBackground) }
    static var cardBackground: Color { adaptive(palette.cardBackground) }
    static var fieldBackground: Color { adaptive(palette.fieldBackground) }

    static var primaryText: Color { adaptive(palette.primaryText) }
    static var secondaryText: Color { adaptive(palette.secondaryText) }
    static var tertiaryText: Color { adaptive(palette.tertiaryText) }
    static var separator: Color { adaptive(palette.separator) }
    static var cardBorder: Color { adaptive(palette.cardBorder) }

    static var mint: Color { adaptive(palette.mint) }
    static var freshGreen: Color { adaptive(palette.freshGreen) }
    static var softWood: Color { adaptive(palette.softWood) }
    static var softBlueGray: Color { adaptive(palette.softBlueGray) }
    static var cream: Color { adaptive(palette.cream) }
    static var apricot: Color { adaptive(palette.apricot) }
    static var blossom: Color { adaptive(palette.blossom) }
    static var skyWash: Color { adaptive(palette.skyWash) }

    static var linkBlue: Color { adaptive(palette.linkBlue) }
    static var dangerRed: Color { adaptive(palette.dangerRed) }
    static var softShadow: Color {
        Color(UIColor { traits in
            if traits.userInterfaceStyle == .dark {
                return UIColor.black.withAlphaComponent(0.28)
            }

            let shadow = palette.shadowLight
            return UIColor(red: shadow.0, green: shadow.1, blue: shadow.2, alpha: 0.08)
        })
    }

    static var weChatGreen: Color { freshGreen }
    static var sky: Color { softBlueGray }
    static var butter: Color { softWood }
    static var matcha: Color { mint }
    static var lavender: Color { softBlueGray }
    static var leafGreen: Color { freshGreen }

    static func markColor(_ markColor: MarkColor) -> Color {
        switch markColor {
        case .none: return fieldBackground
        case .green: return adaptive(palette.markGreen)
        case .yellow: return adaptive(palette.markYellow)
        case .pink: return adaptive(palette.markPink)
        case .gray: return adaptive(palette.markGray)
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
import SwiftUI

struct StatusBadge: View {
    @Environment(\.appLanguage) private var appLanguage

    let status: WishItemStatus

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: status.iconName)
                .font(.system(size: 10, weight: .regular))
            Text(appLanguage.text(status.title))
                .font(.system(size: 12, weight: .regular))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(HWTheme.fieldBackground)
        )
    }

    private var color: Color {
        switch status {
        case .waiting: return HWTheme.freshGreen
        case .bought: return HWTheme.softBlueGray
        case .released: return HWTheme.tertiaryText
        }
    }
}

enum WishChangeEffectKind: Equatable {
    case status(WishItemStatus)
    case trashed
    case restored

    var titleKey: String {
        switch self {
        case .status(let status): return status.title
        case .trashed: return "已放入回收站"
        case .restored: return "已恢复"
        }
    }

    var iconName: String {
        switch self {
        case .status(.waiting): return "heart.fill"
        case .status(.bought): return "checkmark.seal.fill"
        case .status(.released): return "xmark.circle.fill"
        case .trashed: return "trash.fill"
        case .restored: return "arrow.uturn.left.circle.fill"
        }
    }

    var accentIconName: String {
        switch self {
        case .status(.waiting): return "heart"
        case .status(.bought): return "sparkles"
        case .status(.released): return "wind"
        case .trashed: return "tray.and.arrow.down"
        case .restored: return "arrow.uturn.left"
        }
    }

    var color: Color {
        switch self {
        case .status(.waiting), .restored: return HWTheme.freshGreen
        case .status(.bought): return HWTheme.softBlueGray
        case .status(.released): return HWTheme.tertiaryText
        case .trashed: return HWTheme.dangerRed
        }
    }

    var backgroundColor: Color {
        switch self {
        case .status(.waiting), .restored: return HWTheme.mint.opacity(0.30)
        case .status(.bought): return HWTheme.skyWash.opacity(0.40)
        case .status(.released): return HWTheme.fieldBackground
        case .trashed: return HWTheme.dangerRed.opacity(0.12)
        }
    }
}

struct WishChangeEffect: Identifiable, Equatable {
    let id = UUID()
    let kind: WishChangeEffectKind
}

struct WishChangeEffectView: View {
    @Environment(\.appLanguage) private var appLanguage

    let effect: WishChangeEffect

    @State private var isAnimating = false

    private let burstOffsets = [
        CGSize(width: -34, height: -28),
        CGSize(width: 34, height: -30),
        CGSize(width: -28, height: 30),
        CGSize(width: 30, height: 26)
    ]

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(effect.kind.backgroundColor)
                    .frame(width: 78, height: 78)
                    .scaleEffect(isAnimating ? 1.08 : 0.72)

                ForEach(Array(burstOffsets.enumerated()), id: \.offset) { index, offset in
                    Image(systemName: effect.kind.accentIconName)
                        .font(.system(size: index.isMultiple(of: 2) ? 13 : 11, weight: .medium))
                        .foregroundStyle(effect.kind.color.opacity(0.78))
                        .offset(isAnimating ? offset : .zero)
                        .scaleEffect(isAnimating ? 1.18 : 0.42)
                        .opacity(isAnimating ? 0 : 0.88)
                }

                Image(systemName: effect.kind.iconName)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(effect.kind.color)
                    .scaleEffect(isAnimating ? 1 : 0.68)
                    .rotationEffect(.degrees(isAnimating ? 0 : -8))
            }

            Text(appLanguage.text(effect.kind.titleKey))
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(HWTheme.primaryText)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(HWTheme.cardBackground.opacity(0.96))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(effect.kind.color.opacity(0.32), lineWidth: 1)
        )
        .shadow(color: HWTheme.softShadow, radius: 14, x: 0, y: 8)
        .scaleEffect(isAnimating ? 1 : 0.86)
        .opacity(isAnimating ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.72)) {
                isAnimating = true
            }
        }
        .accessibilityElement(children: .combine)
    }
}

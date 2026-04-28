import SwiftUI
import UIKit

struct WishRowView: View {
    @Environment(\.appLanguage) private var appLanguage

    let item: WishItem
    let isEditing: Bool
    let isSelected: Bool
    let onCheck: () -> Void
    let onOpen: () -> Void
    let onMore: (() -> Void)?

    var body: some View {
        HStack(spacing: 10) {
            if item.markColor != .none {
                Rectangle()
                    .fill(HWTheme.markColor(item.markColor))
                    .frame(width: 3)
            }

            Button(action: onCheck) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(bubbleColor.opacity(0.12))
                        .frame(width: 42, height: 42)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(bubbleColor.opacity(0.34), lineWidth: 0.8)
                        )

                    Image(systemName: bubbleIcon)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(bubbleColor)
                }
            }
            .buttonStyle(.plain)

            Button(action: onOpen) {
                HStack(alignment: .center, spacing: 10) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.title)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(item.status == .released ? HWTheme.secondaryText : HWTheme.primaryText)
                            .strikethrough(item.status == .released, color: HWTheme.secondaryText)
                            .lineLimit(1)

                        HStack(spacing: 6) {
                            statusDot
                            Text(subtitle)
                                .font(.system(size: 13))
                                .foregroundStyle(HWTheme.secondaryText)
                                .lineLimit(1)
                        }

                        if item.savingsTarget != nil {
                            savingsBar
                        }
                    }

                    Spacer(minLength: 8)

                    if let priceText {
                        Text(priceText)
                            .font(.system(size: 14, weight: .medium).monospacedDigit())
                            .foregroundStyle(HWTheme.softBlueGray)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(HWTheme.fieldBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if let onMore, !isEditing {
                Button(action: onMore) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(HWTheme.tertiaryText)
                        .frame(width: 32, height: 32)
                        .background(HWTheme.fieldBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(HWTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(HWTheme.cardBorder.opacity(0.68), lineWidth: 0.8)
        )
        .shadow(color: HWTheme.softShadow, radius: 3, x: 0, y: 1)
    }

    private var bubbleIcon: String {
        if isEditing { return isSelected ? "checkmark" : "circle" }
        return item.status.iconName
    }

    private var bubbleColor: Color {
        if isEditing { return isSelected ? HWTheme.freshGreen : HWTheme.tertiaryText }
        if item.markColor != .none { return HWTheme.markColor(item.markColor) }
        return statusColor
    }

    private var statusDot: some View {
        Image(systemName: "circle.fill")
            .font(.system(size: 5, weight: .regular))
            .foregroundStyle(statusColor)
    }

    private var statusColor: Color {
        switch item.status {
        case .waiting: return HWTheme.freshGreen
        case .bought: return HWTheme.softBlueGray
        case .released: return HWTheme.tertiaryText
        }
    }

    private var savingsBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(HWTheme.fieldBackground)

                Capsule()
                    .fill(item.isSavingsComplete ? HWTheme.softBlueGray : HWTheme.freshGreen.opacity(0.72))
                    .frame(width: proxy.size.width * item.savingsProgress)
            }
        }
        .frame(height: 4)
        .padding(.top, 1)
    }

    private var priceText: String? {
        guard let price = item.price else { return nil }
        return "¥\(price.formatted(.number.precision(.fractionLength(0...2))))"
    }

    private var subtitle: String {
        switch item.status {
        case .bought:
            return appLanguage.text(item.status.title)
        case .released:
            return appLanguage.text(item.status.title)
        case .waiting:
            return savingsText
        }
    }

    private var savingsText: String {
        guard let target = item.savingsTarget else {
            return item.category.isEmpty ? appLanguage.text(item.status.title) : localizedCategory(item.category)
        }

        if item.isSavingsComplete {
            return appLanguage.text("已存满")
        }

        let percent = Int((item.savingsProgress * 100).rounded())
        let savedText = moneyText(item.savedAmountValue)
        let targetText = moneyText(target)
        return "\(appLanguage.text("已存")) \(savedText) / \(targetText) · \(percent)%"
    }

    private func localizedCategory(_ category: String) -> String {
        appLanguage.text(category)
    }

    private func moneyText(_ value: Double) -> String {
        "¥\(value.formatted(.number.precision(.fractionLength(0...0))))"
    }
}

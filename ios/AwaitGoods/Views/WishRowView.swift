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

            thumbnail

            Button(action: onOpen) {
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.title)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(item.status == .released ? HWTheme.secondaryText : HWTheme.primaryText)
                            .strikethrough(item.status == .released, color: HWTheme.secondaryText)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: 6) {
                            statusDot
                            Text(subtitle)
                                .font(.system(size: 13))
                                .foregroundStyle(HWTheme.secondaryText)
                                .lineLimit(1)
                        }

                        if item.savingsTarget != nil {
                            savingsProgressSummary
                            savingsBar
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    trailingMeta
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
        .padding(.vertical, 11)
        .background(HWTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(HWTheme.cardBorder.opacity(0.68), lineWidth: 0.8)
        )
        .shadow(color: HWTheme.softShadow, radius: 3, x: 0, y: 1)
    }

    private var thumbnail: some View {
        Button(action: onCheck) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(bubbleColor.opacity(0.11))
                    .overlay(
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .stroke(bubbleColor.opacity(0.22), lineWidth: 0.8)
                    )

                Image(systemName: thumbnailIcon)
                    .font(.system(size: 27, weight: .regular))
                    .foregroundStyle(bubbleColor)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Image(systemName: bubbleIcon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(bubbleColor)
                    .frame(width: 27, height: 27)
                    .background(HWTheme.cardBackground)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(HWTheme.cardBorder.opacity(0.6), lineWidth: 0.7))
                    .offset(x: -5, y: 5)
            }
            .frame(width: 68, height: 76)
        }
        .buttonStyle(.plain)
    }

    private var thumbnailIcon: String {
        let value = item.category.lowercased()
        if value.contains("数码") || value.contains("digital") { return "laptopcomputer" }
        if value.contains("衣") || value.contains("cloth") { return "tshirt" }
        if value.contains("家居") || value.contains("home") { return "house" }
        if value.contains("书") || value.contains("book") { return "books.vertical" }
        if value.contains("礼物") || value.contains("gift") { return "gift" }
        if value.contains("运动") || value.contains("sport") { return "figure.run" }
        if value.contains("体验") || value.contains("travel") { return "airplane" }
        return "bag"
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

    private var priorityBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(priorityColor)
                .frame(width: 5, height: 5)

            Text(appLanguage.text(item.priority.title))
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(priorityColor)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(priorityColor.opacity(0.13))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(priorityColor.opacity(0.28), lineWidth: 0.7)
        )
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityLabel("\(appLanguage.text(item.priority.title))\(appLanguage.text("优先级"))")
    }

    private var trailingMeta: some View {
        VStack(alignment: .trailing, spacing: 6) {
            priorityBadge

            if let priceText {
                Text(priceText)
                    .font(.system(size: 17, weight: .semibold).monospacedDigit())
                    .foregroundStyle(HWTheme.savingsProgressColor(item.savingsProgress, isComplete: item.isSavingsComplete))
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
            }
        }
        .frame(minWidth: 58, alignment: .topTrailing)
        .layoutPriority(1)
    }

    private var priorityColor: Color {
        switch item.priority {
        case .low: return HWTheme.softBlueGray
        case .medium: return HWTheme.apricot
        case .high: return HWTheme.dangerRed
        }
    }

    private var savingsBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(HWTheme.fieldBackground)

                Capsule()
                    .fill(HWTheme.savingsProgressColor(item.savingsProgress, isComplete: item.isSavingsComplete))
                    .frame(width: proxy.size.width * item.savingsProgress)
            }
        }
        .frame(height: 4)
        .padding(.top, 1)
    }

    private var savingsProgressSummary: some View {
        HStack(spacing: 4) {
            if let target = item.savingsTarget {
                Text("\(appLanguage.text("已存")) \(moneyText(item.savedAmountValue)) / \(moneyText(target))")
            }

            Spacer(minLength: 4)

            Text("\(Int((item.savingsProgress * 100).rounded()))%")
                .fontWeight(.semibold)
                .foregroundStyle(HWTheme.savingsProgressColor(item.savingsProgress, isComplete: item.isSavingsComplete))
        }
        .font(.system(size: 12, weight: .regular).monospacedDigit())
        .foregroundStyle(HWTheme.secondaryText)
        .lineLimit(1)
        .minimumScaleFactor(0.78)
    }

    private var priceText: String? {
        guard let price = item.price else { return nil }
        return "$\(price.formatted(.number.precision(.fractionLength(0...2))))"
    }

    private var subtitle: String {
        switch item.status {
        case .bought:
            return appLanguage.text(item.status.title)
        case .released:
            return appLanguage.text(item.status.title)
        case .waiting:
            return item.category.isEmpty ? appLanguage.text(item.status.title) : localizedCategory(item.category)
        }
    }

    private func localizedCategory(_ category: String) -> String {
        appLanguage.text(category)
    }

    private func moneyText(_ value: Double) -> String {
        "$\(value.formatted(.number.precision(.fractionLength(0...0))))"
    }
}

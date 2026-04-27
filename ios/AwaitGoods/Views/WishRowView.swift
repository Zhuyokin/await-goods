import SwiftUI
import UIKit

struct WishRowView: View {
    let item: WishItem
    let isEditing: Bool
    let isSelected: Bool
    let onCheck: () -> Void
    let onOpen: () -> Void

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
                    VStack(alignment: .leading, spacing: 4) {
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
        switch item.status {
        case .waiting, .bought, .released, .paused: return item.status.iconName
        }
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
        case .paused: return HWTheme.softWood
        }
    }

    private var priceText: String? {
        guard let price = item.price else { return nil }
        return "¥\(price.formatted(.number.precision(.fractionLength(0...2))))"
    }

    private var subtitle: String {
        switch item.status {
        case .bought:
            return item.status.title
        case .released:
            return item.status.title
        case .paused:
            return item.status.title
        case .waiting:
            return waitText
        }
    }

    private var waitText: String {
        guard let waitUntil = item.waitUntil else { return item.category.isEmpty ? item.status.title : item.category }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.startOfDay(for: waitUntil)
        let days = calendar.dateComponents([.day], from: start, to: end).day ?? 0

        if days > 0 { return "还要等 \(days) 天" }
        if days == 0 { return "今天可决定" }
        return "可以再看看了"
    }
}

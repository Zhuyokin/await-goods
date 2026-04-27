import SwiftUI
import UIKit

struct WishRowView: View {
    let item: WishItem
    let isEditing: Bool
    let isSelected: Bool
    let onCheck: () -> Void
    let onOpen: () -> Void

    var body: some View {
        HStack(spacing: 11) {
            if item.markColor != .none {
                Rectangle()
                    .fill(HWTheme.markColor(item.markColor))
                    .frame(width: 3)
            }

            Button(action: onCheck) {
                ZStack {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(bubbleColor.opacity(0.20))
                        .frame(width: 44, height: 44)
                        .shadow(color: bubbleColor.opacity(0.22), radius: 8, x: 0, y: 4)

                    Image(systemName: bubbleIcon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(bubbleColor)
                }
            }
            .buttonStyle(.plain)

            Button(action: onOpen) {
                HStack(alignment: .center, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.system(size: 18, weight: .medium))
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
                            .foregroundStyle(HWTheme.freshGreen)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(HWTheme.mint.opacity(0.16))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(HWTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(HWTheme.cardBorder.opacity(0.55))
        )
        .shadow(color: HWTheme.softShadow, radius: 7, x: 0, y: 4)
    }

    private var bubbleIcon: String {
        if isEditing { return isSelected ? "checkmark" : "circle" }
        switch item.status {
        case .waiting: return "leaf.fill"
        case .bought: return "checkmark"
        case .released: return "minus"
        case .paused: return "pause.fill"
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
        case .waiting: return HWTheme.mint
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
            return "已入手"
        case .released:
            return "已放下"
        case .paused:
            return "搁置"
        case .waiting:
            return waitText
        }
    }

    private var waitText: String {
        guard let waitUntil = item.waitUntil else { return item.category.isEmpty ? "候着" : item.category }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.startOfDay(for: waitUntil)
        let days = calendar.dateComponents([.day], from: start, to: end).day ?? 0

        if days > 0 { return "还要等 \(days) 天" }
        if days == 0 { return "今天可决定" }
        return "可以再看看了"
    }
}

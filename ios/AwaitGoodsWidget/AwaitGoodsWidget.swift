import SwiftUI
import WidgetKit
import UIKit

struct AwaitGoodsEntry: TimelineEntry {
    let date: Date
    let items: [WishSnapshot]
}

struct AwaitGoodsProvider: TimelineProvider {
    func placeholder(in context: Context) -> AwaitGoodsEntry {
        AwaitGoodsEntry(date: Date(), items: sampleItems)
    }

    func getSnapshot(in context: Context, completion: @escaping (AwaitGoodsEntry) -> Void) {
        let items = WidgetSnapshotStore.load()
        completion(AwaitGoodsEntry(date: Date(), items: items.isEmpty ? sampleItems : items))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AwaitGoodsEntry>) -> Void) {
        let entry = AwaitGoodsEntry(date: Date(), items: WidgetSnapshotStore.load())
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private var sampleItems: [WishSnapshot] {
        [
            WishSnapshot(id: UUID(), title: "MacBook 支架", price: 129, savedAmount: 80, sortIndex: 0),
            WishSnapshot(id: UUID(), title: "黑色羊毛大衣", price: 1680, savedAmount: 620, sortIndex: 1),
            WishSnapshot(id: UUID(), title: "咖啡手冲壶", price: 268, savedAmount: 268, sortIndex: 2)
        ]
    }
}

struct AwaitGoodsWidgetView: View {
    @Environment(\.widgetFamily) private var widgetFamily
    let entry: AwaitGoodsEntry

    private var maxCount: Int {
        switch widgetFamily {
        case .systemSmall:
            return 1
        case .systemLarge:
            return 5
        default:
            return 3
        }
    }

    var body: some View {
        Group {
            if widgetFamily == .systemSmall {
                smallWidget
            } else {
                listWidget
            }
        }
        .containerBackground(for: .widget) {
            WidgetPalette.backgroundGradient
        }
        .widgetURL(URL(string: "awaitgoods://home"))
    }

    private var smallWidget: some View {
        VStack(alignment: .leading, spacing: 10) {
            widgetHeader(compact: true)

            Spacer(minLength: 2)

            if let firstItem = entry.items.first {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 4, weight: .regular))
                        Text(savingsText(for: firstItem))
                            .font(.system(size: 12, weight: .regular))
                    }
                    .foregroundStyle(WidgetPalette.green)

                    Text(firstItem.title)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(WidgetPalette.ink)
                        .lineLimit(2)

                    if let priceText = priceText(for: firstItem.price) {
                        Text(priceText)
                            .font(.system(size: 14, weight: .medium).monospacedDigit())
                            .foregroundStyle(WidgetPalette.green)
                    }

                    progressBar(for: firstItem, height: 4)
                }
            } else {
                emptyWidgetText
            }

            Spacer(minLength: 0)

            Text(entry.items.isEmpty ? "今天也很克制" : "轻点打开清单")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(WidgetPalette.secondary)
        }
    }

    private var listWidget: some View {
        VStack(alignment: .leading, spacing: widgetFamily == .systemLarge ? 8 : 10) {
            widgetHeader(compact: false)

            if entry.items.isEmpty {
                Spacer(minLength: 4)
                emptyWidgetText
                Spacer(minLength: 0)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(entry.items.prefix(maxCount))) { item in
                        widgetRow(item)
                    }
                }

                Spacer(minLength: 0)
            }
        }
    }

    private func widgetHeader(compact: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "bag")
                .font(.system(size: compact ? 13 : 14, weight: .regular))
                .foregroundStyle(WidgetPalette.green)

            VStack(alignment: .leading, spacing: 1) {
                Text("候物")
                    .font(.system(size: compact ? 14 : 15, weight: .medium))
                    .foregroundStyle(WidgetPalette.ink)

                if !compact {
                    Text(summaryText)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(WidgetPalette.secondary)
                }
            }

            Spacer(minLength: 4)

            Text(entry.items.isEmpty ? "0" : "\(entry.items.count)")
                .font(.system(size: 12, weight: .regular).monospacedDigit())
                .foregroundStyle(WidgetPalette.secondary)
        }
    }

    private func widgetRow(_ item: WishSnapshot) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "heart")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(WidgetPalette.green)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(WidgetPalette.ink)
                    .lineLimit(1)

                progressBar(for: item, height: 3)
            }

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 2) {
                Text(progressText(for: item))
                    .font(.system(size: 11, weight: .medium).monospacedDigit())
                    .foregroundStyle(WidgetPalette.green)

                Text(savingsText(for: item))
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(WidgetPalette.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(WidgetPalette.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(WidgetPalette.separator)
        )
    }

    private func progressBar(for item: WishSnapshot, height: CGFloat) -> some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(WidgetPalette.field)

                Capsule()
                    .fill(item.savingsProgress >= 1 ? WidgetPalette.apricot : WidgetPalette.green)
                    .frame(width: proxy.size.width * item.savingsProgress)
            }
        }
        .frame(height: height)
    }

    private var emptyWidgetText: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("清单很轻")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(WidgetPalette.ink)

            Text("先记下心动，晚点再决定。")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(WidgetPalette.secondary)
                .lineLimit(2)
        }
    }

    private var summaryText: String {
        entry.items.isEmpty ? "今天没有待存心愿" : "还有 \(entry.items.count) 件想买"
    }

    private func savingsText(for item: WishSnapshot) -> String {
        guard let remaining = item.remainingAmount else { return "想买" }
        if remaining == 0 { return "已存满" }
        return "还差 \(priceText(for: remaining) ?? "¥0")"
    }

    private func progressText(for item: WishSnapshot) -> String {
        guard item.price != nil else { return "--" }
        return "\(Int((item.savingsProgress * 100).rounded()))%"
    }

    private func priceText(for price: Double?) -> String? {
        guard let price else { return nil }
        return "¥\(price.formatted(.number.precision(.fractionLength(0...0))))"
    }
}

private enum WidgetPalette {
    private typealias RGB = (CGFloat, CGFloat, CGFloat)

    private static func adaptive(light: RGB, dark: RGB, alpha: CGFloat = 1) -> Color {
        Color(UIColor { traits in
            let value = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: value.0, green: value.1, blue: value.2, alpha: alpha)
        })
    }

    static let background = adaptive(light: (0.972, 0.982, 0.968), dark: (0.105, 0.112, 0.108))
    static let card = adaptive(light: (1.000, 1.000, 0.996), dark: (0.168, 0.176, 0.166))
    static let field = adaptive(light: (0.936, 0.958, 0.938), dark: (0.214, 0.232, 0.214))
    static let primary = adaptive(light: (0.120, 0.142, 0.132), dark: (0.930, 0.948, 0.922))
    static let secondary = adaptive(light: (0.380, 0.430, 0.395), dark: (0.700, 0.744, 0.690))
    static let tertiary = adaptive(light: (0.580, 0.628, 0.590), dark: (0.555, 0.600, 0.558))
    static let border = adaptive(light: (0.800, 0.852, 0.802), dark: (0.328, 0.365, 0.330))
    static let green = adaptive(light: (0.290, 0.520, 0.370), dark: (0.610, 0.780, 0.610))
    static let mint = adaptive(light: (0.780, 0.882, 0.780), dark: (0.430, 0.575, 0.435))
    static let apricot = adaptive(light: (0.800, 0.580, 0.460), dark: (0.725, 0.510, 0.410))
    static let backgroundLight = adaptive(light: (0.992, 0.994, 0.988), dark: (0.132, 0.138, 0.132))
    static let backgroundBase = background
    static let ink = primary
    static let separator = border.opacity(0.64)

    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [backgroundLight, backgroundBase],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct AwaitGoodsWidget: Widget {
    let kind = "AwaitGoodsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AwaitGoodsProvider()) { entry in
            AwaitGoodsWidgetView(entry: entry)
        }
        .configurationDisplayName("候物")
        .description("查看正在想买的物品。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@main
struct AwaitGoodsWidgetBundle: WidgetBundle {
    var body: some Widget {
        AwaitGoodsWidget()
    }
}
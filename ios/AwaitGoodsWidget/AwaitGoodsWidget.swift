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
            WishSnapshot(id: UUID(), title: "MacBook 支架", price: 129, waitUntil: Calendar.current.date(byAdding: .day, value: 5, to: Date()), sortIndex: 0),
            WishSnapshot(id: UUID(), title: "黑色羊毛大衣", price: 1680, waitUntil: Date(), sortIndex: 1),
            WishSnapshot(id: UUID(), title: "咖啡手冲壶", price: 268, waitUntil: Calendar.current.date(byAdding: .day, value: 12, to: Date()), sortIndex: 2)
        ]
    }
}

struct AwaitGoodsWidgetView: View {
    @Environment(\.widgetFamily) private var widgetFamily
    let entry: AwaitGoodsEntry

    private var maxCount: Int {
        widgetFamily == .systemSmall ? 1 : 3
    }

    var body: some View {
        Group {
            if widgetFamily == .systemSmall {
                smallWidget
            } else {
                mediumWidget
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
                        Text(waitText(for: firstItem.waitUntil))
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

    private var mediumWidget: some View {
        VStack(alignment: .leading, spacing: 11) {
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
        HStack(spacing: 9) {
            Image(systemName: "square")
                .font(.system(size: 16, weight: .ultraLight))
                .foregroundStyle(WidgetPalette.tertiary)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(WidgetPalette.ink)
                    .lineLimit(1)

                HStack(spacing: 5) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 4, weight: .regular))
                        .foregroundStyle(WidgetPalette.mint)

                    Text(waitText(for: item.waitUntil))
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(WidgetPalette.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 4)

            if let priceText = priceText(for: item.price) {
                Text(priceText)
                    .font(.system(size: 12, weight: .medium).monospacedDigit())
                    .foregroundStyle(WidgetPalette.green)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(WidgetPalette.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(WidgetPalette.separator)
        )
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
        entry.items.isEmpty ? "今天没有待决定" : "还有 \(entry.items.count) 件等一等"
    }

    private func waitText(for date: Date?) -> String {
        guard let date else { return "候着" }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.startOfDay(for: date)
        let days = calendar.dateComponents([.day], from: start, to: end).day ?? 0

        if days > 0 { return "还等 \(days) 天" }
        if days == 0 { return "今天决定" }
        return "可再看"
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

    static let background = adaptive(light: (0.988, 0.961, 0.910), dark: (0.105, 0.094, 0.078))
    static let card = adaptive(light: (1.000, 0.986, 0.956), dark: (0.170, 0.150, 0.122))
    static let field = adaptive(light: (0.965, 0.925, 0.858), dark: (0.215, 0.188, 0.150))
    static let primary = adaptive(light: (0.260, 0.220, 0.180), dark: (0.940, 0.910, 0.865))
    static let secondary = adaptive(light: (0.555, 0.488, 0.415), dark: (0.725, 0.660, 0.575))
    static let tertiary = adaptive(light: (0.700, 0.625, 0.540), dark: (0.555, 0.500, 0.435))
    static let border = adaptive(light: (0.910, 0.845, 0.745), dark: (0.335, 0.292, 0.232))
    static let green = adaptive(light: (0.260, 0.635, 0.485), dark: (0.560, 0.760, 0.565))
    static let mint = adaptive(light: (0.740, 0.812, 0.650), dark: (0.500, 0.615, 0.410))
    static let apricot = adaptive(light: (0.945, 0.710, 0.545), dark: (0.725, 0.455, 0.345))
    static let backgroundLight = adaptive(light: (0.996, 0.976, 0.937), dark: (0.130, 0.116, 0.096))
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
        .description("查看正在候着的物品。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct AwaitGoodsWidgetBundle: WidgetBundle {
    var body: some Widget {
        AwaitGoodsWidget()
    }
}
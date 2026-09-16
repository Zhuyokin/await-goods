import SwiftUI
import WidgetKit
import UIKit

struct AwaitGoodsEntry: TimelineEntry {
    let date: Date
    let items: [WishSnapshot]
}

import AppIntents

struct WishGroupEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "内容分组"
    static var defaultQuery = WishGroupQuery()
    let id: String
    let name: String
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)") }
    static let all = WishGroupEntity(id: "all", name: NSLocalizedString("全部心愿", comment: "All widget groups"))
    var group: String? { id == "all" ? nil : name }
}

struct WishGroupQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [WishGroupEntity] {
        identifiers.map { id in
            id == "all" ? .all : WishGroupEntity(id: id, name: String(id.dropFirst("group:".count)))
        }
    }
    func suggestedEntities() async throws -> [WishGroupEntity] {
        var seen = Set<String>()
        let groups = WidgetSnapshotStore.load().flatMap(\.groups).filter { seen.insert($0).inserted }
        return [.all] + groups.map { WishGroupEntity(id: "group:" + $0, name: $0) }
    }
    func defaultResult() async -> WishGroupEntity? { .all }
}

struct WishProductEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "心愿商品"
    static var defaultQuery = WishProductQuery()
    let id: UUID
    let name: String
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)") }
}

struct WishProductQuery: EntityStringQuery {
    func entities(for identifiers: [UUID]) async throws -> [WishProductEntity] {
        WidgetSnapshotStore.load().filter { identifiers.contains($0.id) }.map { WishProductEntity(id: $0.id, name: $0.title) }
    }
    func suggestedEntities() async throws -> [WishProductEntity] {
        WidgetSnapshotStore.load().map { WishProductEntity(id: $0.id, name: $0.title) }
    }
    func entities(matching string: String) async throws -> [WishProductEntity] {
        try await suggestedEntities().filter { $0.name.localizedCaseInsensitiveContains(string) }
    }
}

struct WishWidgetConfiguration: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "心愿分组"
    static var description = IntentDescription("独立选择这个小组件显示的内容。")
    @Parameter(title: "内容分组") var group: WishGroupEntity?
    static var parameterSummary: some ParameterSummary { Summary { \.$group } }
    init() { group = .all }
    init(group: WishGroupEntity) { self.group = group }
}

struct WishPhotoConfiguration: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "心动单品"
    static var description = IntentDescription("选择分组，或指定一件商品优先展示。")
    @Parameter(title: "内容分组") var group: WishGroupEntity?
    @Parameter(title: "指定商品（优先展示）") var product: WishProductEntity?
    static var parameterSummary: some ParameterSummary { Summary { \.$group; \.$product } }
    init() { group = .all }
}

struct AwaitGoodsProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> AwaitGoodsEntry { previewEntry }
    func snapshot(for configuration: WishWidgetConfiguration, in context: Context) async -> AwaitGoodsEntry {
        configuredEntry(group: configuration.group?.group, preview: context.isPreview)
    }
    func timeline(for configuration: WishWidgetConfiguration, in context: Context) async -> Timeline<AwaitGoodsEntry> {
        Timeline(entries: [configuredEntry(group: configuration.group?.group)], policy: .after(Date().addingTimeInterval(1800)))
    }
}

struct WishPhotoProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> AwaitGoodsEntry { previewEntry }
    func snapshot(for configuration: WishPhotoConfiguration, in context: Context) async -> AwaitGoodsEntry {
        configuredEntry(group: configuration.group?.group, itemID: configuration.product?.id, preview: context.isPreview)
    }
    func timeline(for configuration: WishPhotoConfiguration, in context: Context) async -> Timeline<AwaitGoodsEntry> {
        Timeline(entries: [configuredEntry(group: configuration.group?.group, itemID: configuration.product?.id)], policy: .after(Date().addingTimeInterval(1800)))
    }
}

private var previewEntry: AwaitGoodsEntry {
    AwaitGoodsEntry(date: Date(), items: [
        WishSnapshot(id: UUID(), title: "Weekend bag", price: 1200, savedAmount: 720, sortIndex: 0),
        WishSnapshot(id: UUID(), title: "Classic watch", price: 2400, savedAmount: 1800, sortIndex: 1),
        WishSnapshot(id: UUID(), title: "Travel camera", price: 980, savedAmount: 420, sortIndex: 2)
    ])
}

private func configuredEntry(group: String?, itemID: UUID? = nil, preview: Bool = false) -> AwaitGoodsEntry {
    let items = WidgetSnapshotStore.load()
    if preview && items.isEmpty && group == nil && itemID == nil { return previewEntry }
    return AwaitGoodsEntry(date: Date(), items: WidgetContentFilter.select(items, group: group, itemID: itemID))
}

struct AwaitGoodsWidgetView: View {
    @Environment(\.widgetFamily) private var widgetFamily
    let entry: AwaitGoodsEntry

    private var copy: WidgetCopy {
        WidgetCopy(languageCode: WidgetSnapshotStore.loadLanguageCode())
    }

    private var maxCount: Int {
        switch widgetFamily {
        case .systemSmall:
            return 1
        case .systemLarge:
            return 5
        default:
            return 2
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
            Image("WidgetAppIcon")
                .resizable()
                .scaledToFit()
                .frame(width: compact ? 18 : 20, height: compact ? 18 : 20)
                .clipShape(RoundedRectangle(cornerRadius: compact ? 4 : 5, style: .continuous))

            VStack(alignment: .leading, spacing: 1) {
                Text(copy.appName)
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
            WidgetProductPhoto(item: item)
                .frame(width: 28, height: 28)

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
        .padding(.vertical, 4)
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
            Text(copy.emptyTitle)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(WidgetPalette.ink)

            Text(copy.emptySubtitle)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(WidgetPalette.secondary)
                .lineLimit(2)
        }
    }

    private var summaryText: String {
        entry.items.isEmpty ? copy.emptySummary : copy.waitingSummary(count: entry.items.count)
    }

    private func savingsText(for item: WishSnapshot) -> String {
        guard let remaining = item.remainingAmount else { return copy.wantedText }
        if remaining == 0 { return copy.completedText }
        return copy.remainingText(priceText(for: remaining) ?? "$0")
    }

    private func progressText(for item: WishSnapshot) -> String {
        guard item.price != nil else { return "--" }
        return "\(Int((item.savingsProgress * 100).rounded()))%"
    }

    private func priceText(for price: Double?) -> String? {
        guard let price else { return nil }
        return "$\(price.formatted(.number.precision(.fractionLength(0...0))))"
    }
}

private struct WidgetCopy {
    private enum Language {
        case zhHans
        case zhHant
        case en

        init(languageCode: String) {
            switch languageCode {
            case "zhHans": self = .zhHans
            case "zhHant": self = .zhHant
            case "en": self = .en
            default: self = .en
            }
        }
    }

    private let language: Language

    init(languageCode: String) {
        language = Language(languageCode: languageCode)
    }

    var appName: String {
        switch language {
        case .zhHans, .zhHant: return "候物"
        case .en: return "AwaitGoods"
        }
    }

    func localized(_ simplified: String, _ traditional: String, _ english: String) -> String {
        switch language {
        case .zhHans: return simplified
        case .zhHant: return traditional
        case .en: return english
        }
    }

    var photoTitle: String { localized("心动单品", "心動單品", "In focus") }
    var savingsTitle: String { localized("心愿储蓄", "心願儲蓄", "Wish savings") }
    var galleryTitle: String { localized("心愿照片墙", "心願照片牆", "Wish gallery") }
    var savedLabel: String { localized("已存", "已存", "Saved") }
    var targetLabel: String { localized("目标", "目標", "Goal") }

    var restrainedText: String {
        switch language {
        case .zhHans: return "今天也很克制"
        case .zhHant: return "今天也很克制"
        case .en: return "Quiet today"
        }
    }

    var openText: String {
        switch language {
        case .zhHans: return "轻点打开清单"
        case .zhHant: return "輕點打開清單"
        case .en: return "Tap to open"
        }
    }

    var emptyTitle: String {
        switch language {
        case .zhHans: return "清单很轻"
        case .zhHant: return "清單很輕"
        case .en: return "Quiet list"
        }
    }

    var emptySubtitle: String {
        switch language {
        case .zhHans: return "先记下心动，晚点再决定。"
        case .zhHant: return "先記下心動，晚點再決定。"
        case .en: return "Save the wish first. Decide later."
        }
    }

    var emptySummary: String {
        switch language {
        case .zhHans: return "今天没有待存心愿"
        case .zhHant: return "今天沒有待存心願"
        case .en: return "No waiting wishes today"
        }
    }

    var wantedText: String {
        switch language {
        case .zhHans, .zhHant: return "想买"
        case .en: return "Wanted"
        }
    }

    var completedText: String {
        switch language {
        case .zhHans: return "已存满"
        case .zhHant: return "已存滿"
        case .en: return "Saved up"
        }
    }

    func waitingSummary(count: Int) -> String {
        switch language {
        case .zhHans: return "还有 \(count) 件想买"
        case .zhHant: return "還有 \(count) 件想買"
        case .en: return count == 1 ? "1 wish waiting" : "\(count) wishes waiting"
        }
    }

    func remainingText(_ price: String) -> String {
        switch language {
        case .zhHans: return "还差 \(price)"
        case .zhHant: return "還差 \(price)"
        case .en: return "\(price) left"
        }
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
        AppIntentConfiguration(kind: kind, intent: WishWidgetConfiguration.self, provider: AwaitGoodsProvider()) { entry in
            AwaitGoodsWidgetView(entry: entry)
        }
        .configurationDisplayName(NSLocalizedString("AwaitGoodsWidgetName", comment: "Widget display name"))
        .description(NSLocalizedString("AwaitGoodsWidgetDescription", comment: "Widget description"))
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@main
struct AwaitGoodsWidgetBundle: WidgetBundle {
    var body: some Widget {
        AwaitGoodsWidget()
        AwaitGoodsPhotoWidget()
        AwaitGoodsSavingsWidget()
        AwaitGoodsGalleryWidget()
    }
}

private struct WidgetProductPhoto: View {
    let item: WishSnapshot

    var body: some View {
        Group {
            if let filename = item.photoFilename,
               let url = WidgetSnapshotStore.photoURL(filename: filename),
               let image = UIImage(contentsOfFile: url.path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "gift")
                    .resizable()
                    .scaledToFit()
                    .padding(12)
                    .foregroundStyle(WidgetPalette.green.opacity(0.7))
            }
        }
        .accessibilityLabel(item.title)
    }
}

private enum ShowcaseStyle {
    case photo, savings, gallery
}

private struct WishShowcaseView: View {
    @Environment(\.widgetFamily) private var family
    let entry: AwaitGoodsEntry
    let style: ShowcaseStyle

    private var copy: WidgetCopy { WidgetCopy(languageCode: WidgetSnapshotStore.loadLanguageCode()) }
    private var isSmall: Bool { family == .systemSmall }
    private var isLarge: Bool { family == .systemLarge }
    private var pricedItems: [WishSnapshot] { entry.items.filter { ($0.price ?? 0) > 0 } }
    private var target: Double { pricedItems.reduce(0) { $0 + ($1.price ?? 0) } }
    private var saved: Double { pricedItems.reduce(0) { $0 + min(max($1.savedAmount, 0), $1.price ?? 0) } }
    private var progress: Double { target > 0 ? min(saved / target, 1) : 0 }
    private var title: String {
        switch style {
        case .photo: return copy.photoTitle
        case .savings: return copy.savingsTitle
        case .gallery: return copy.galleryTitle
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: isSmall ? 8 : 12) {
            header
            if entry.items.isEmpty {
                Spacer(minLength: 0)
                Text(copy.emptyTitle)
                    .font(.system(size: 19, weight: .semibold, design: .rounded))
                Text(copy.emptySubtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(WidgetPalette.secondary)
                Spacer(minLength: 0)
            } else {
                switch style {
                case .photo: photoContent
                case .savings: savingsContent
                case .gallery: galleryContent
                }
            }
        }
        .foregroundStyle(WidgetPalette.ink)
        .containerBackground(for: .widget) { WidgetPalette.backgroundGradient }
        .widgetURL(URL(string: "awaitgoods://home"))
    }

    private var header: some View {
        HStack(spacing: 6) {
            Image("WidgetAppIcon")
                .resizable()
                .frame(width: 16, height: 16)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 0)
            if !isSmall {
                Text(copy.appName)
                    .font(.system(size: 10))
                    .foregroundStyle(WidgetPalette.secondary)
            }
        }
    }

    @ViewBuilder
    private var photoContent: some View {
        if let item = entry.items.first {
            if isSmall {
                WidgetProductPhoto(item: item)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Text(item.title)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                progressBar(item.savingsProgress)
            } else if isLarge {
                WidgetProductPhoto(item: item)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.vertical, 6)
                itemDetails(item, large: true)
            } else {
                HStack(spacing: 16) {
                    GeometryReader { geometry in
                        WidgetProductPhoto(item: item)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                    }
                    itemDetails(item, large: false)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private func itemDetails(_ item: WishSnapshot, large: Bool) -> some View {
        VStack(alignment: .leading, spacing: large ? 9 : 6) {
            Text(item.title)
                .font(.system(size: large ? 20 : 16, weight: .semibold, design: .rounded))
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            HStack(alignment: .firstTextBaseline) {
                Text(item.price.map(money) ?? copy.wantedText)
                    .font(.system(size: large ? 22 : 17, weight: .medium, design: .rounded))
                    .foregroundStyle(WidgetPalette.green)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 0)
                Text(percent(item.savingsProgress))
                    .font(.system(size: 11, weight: .medium).monospacedDigit())
                    .foregroundStyle(WidgetPalette.secondary)
            }
            progressBar(item.savingsProgress)
            if let remaining = item.remainingAmount {
                Text(remaining == 0 ? copy.completedText : copy.remainingText(money(remaining)))
                    .font(.system(size: 11))
                    .foregroundStyle(WidgetPalette.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
    }

    @ViewBuilder
    private var savingsContent: some View {
        if isSmall {
            savingsRing
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            HStack {
                Text(copy.savedLabel)
                    .foregroundStyle(WidgetPalette.secondary)
                Spacer(minLength: 0)
                Text(money(saved))
                    .fontWeight(.semibold)
                    .minimumScaleFactor(0.6)
            }
            .font(.system(size: 11).monospacedDigit())
            .lineLimit(1)
        } else if isLarge {
            savingsRing
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, 4)
            savingsAmounts
            Divider().overlay(WidgetPalette.separator)
            ForEach(Array(pricedItems.prefix(2))) { item in
                HStack(spacing: 8) {
                    WidgetProductPhoto(item: item).frame(width: 26, height: 26)
                    Text(item.title).lineLimit(1)
                    Spacer(minLength: 0)
                    Text(percent(item.savingsProgress)).foregroundStyle(WidgetPalette.green)
                }
                .font(.system(size: 11, weight: .medium))
            }
        } else {
            HStack(spacing: 20) {
                savingsRing.frame(maxWidth: .infinity)
                savingsAmounts.frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: .infinity)
        }
    }

    private var savingsRing: some View {
        GeometryReader { geometry in
            let diameter = min(geometry.size.width, geometry.size.height)
            ZStack {
                Circle().stroke(WidgetPalette.field, lineWidth: isSmall ? 7 : 10)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(AngularGradient(colors: [WidgetPalette.mint, WidgetPalette.green], center: .center, startAngle: .degrees(0), endAngle: .degrees(360)), style: StrokeStyle(lineWidth: isSmall ? 7 : 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 2) {
                    Text(target > 0 ? percent(progress) : "—")
                        .font(.system(size: isSmall ? 22 : 30, weight: .medium, design: .rounded).monospacedDigit())
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                    if !isSmall {
                        Text(copy.savedLabel)
                            .font(.system(size: 10))
                            .foregroundStyle(WidgetPalette.secondary)
                    }
                }
                .padding(10)
            }
            .frame(width: max(diameter - 12, 0), height: max(diameter - 12, 0))
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .accessibilityLabel("\(copy.savedLabel) \(money(saved)), \(percent(progress))")
    }

    private var savingsAmounts: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(copy.savedLabel)
                .font(.system(size: 11))
                .foregroundStyle(WidgetPalette.secondary)
            Text(money(saved))
                .font(.system(size: isLarge ? 28 : 23, weight: .medium, design: .rounded).monospacedDigit())
                .foregroundStyle(WidgetPalette.green)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text("\(copy.targetLabel) · \(money(target))")
                .font(.system(size: 11))
                .foregroundStyle(WidgetPalette.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private var galleryContent: some View {
        GeometryReader { geometry in
            let columns = isLarge ? 2 : 3
            let rows = isLarge ? 2 : 1
            let cellHeight = max((geometry.size.height - CGFloat(rows - 1) * 10) / CGFloat(rows), 0)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: columns), spacing: 10) {
                ForEach(Array(entry.items.prefix(columns * rows))) { item in
                    VStack(alignment: .leading, spacing: 5) {
                        WidgetProductPhoto(item: item)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        Text(item.title)
                            .font(.system(size: isLarge ? 12 : 10, weight: .medium))
                            .lineLimit(1)
                        progressBar(item.savingsProgress)
                    }
                    .padding(isLarge ? 10 : 8)
                    .frame(height: cellHeight)
                    .background(WidgetPalette.card, in: RoundedRectangle(cornerRadius: 16))
                }
            }
        }
    }

    private func progressBar(_ progress: Double) -> some View {
        GeometryReader { geometry in
            Capsule().fill(WidgetPalette.field)
                .overlay(alignment: .leading) {
                    Capsule().fill(WidgetPalette.green)
                        .frame(width: geometry.size.width * progress)
                }
        }
        .frame(height: 4)
        .accessibilityLabel(percent(progress))
    }

    private func money(_ value: Double) -> String {
        "$\(value.formatted(.number.precision(.fractionLength(0))))"
    }

    private func percent(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }
}

struct AwaitGoodsPhotoWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "AwaitGoodsPhotoWidget", intent: WishPhotoConfiguration.self, provider: WishPhotoProvider()) { entry in
            WishShowcaseView(entry: entry, style: .photo)
        }
        .configurationDisplayName(NSLocalizedString("PhotoWidgetName", comment: ""))
        .description(NSLocalizedString("PhotoWidgetDescription", comment: ""))
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct AwaitGoodsSavingsWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "AwaitGoodsSavingsWidget", intent: WishWidgetConfiguration.self, provider: AwaitGoodsProvider()) { entry in
            WishShowcaseView(entry: entry, style: .savings)
        }
        .configurationDisplayName(NSLocalizedString("SavingsWidgetName", comment: ""))
        .description(NSLocalizedString("SavingsWidgetDescription", comment: ""))
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct AwaitGoodsGalleryWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "AwaitGoodsGalleryWidget", intent: WishWidgetConfiguration.self, provider: AwaitGoodsProvider()) { entry in
            WishShowcaseView(entry: entry, style: .gallery)
        }
        .configurationDisplayName(NSLocalizedString("GalleryWidgetName", comment: ""))
        .description(NSLocalizedString("GalleryWidgetDescription", comment: ""))
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

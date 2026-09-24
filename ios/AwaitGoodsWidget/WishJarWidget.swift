import SwiftUI
import WidgetKit
import AppIntents
import UIKit
import ImageIO

struct WishJarEntry: TimelineEntry {
    let date: Date
    let items: [WishSnapshot]
    let selectedID: UUID?
    let scope: String
    let languageCode: String
}

struct WishJarProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> WishJarEntry { preview }

    func snapshot(for configuration: WishWidgetConfiguration, in context: Context) async -> WishJarEntry {
        if context.isPreview && WidgetSnapshotStore.load().isEmpty { return preview }
        return entry(for: configuration)
    }

    func timeline(for configuration: WishWidgetConfiguration, in context: Context) async -> Timeline<WishJarEntry> {
        Timeline(entries: [entry(for: configuration)], policy: .after(Date().addingTimeInterval(1800)))
    }

    private func entry(for configuration: WishWidgetConfiguration) -> WishJarEntry {
        let scope = configuration.group?.id ?? "all"
        return WishJarEntry(date: Date(),
                            items: WidgetContentFilter.select(WidgetSnapshotStore.load(), group: configuration.group?.group),
                            selectedID: WishJarState.selection(scope: scope), scope: scope,
                            languageCode: WidgetSnapshotStore.loadLanguageCode())
    }

    private var preview: WishJarEntry {
        WishJarEntry(date: Date(), items: [
            WishSnapshot(id: UUID(), title: "Weekend bag", price: 1200, savedAmount: 720, sortIndex: 0),
            WishSnapshot(id: UUID(), title: "Classic watch", price: 2400, savedAmount: 1800, sortIndex: 1),
            WishSnapshot(id: UUID(), title: "Travel camera", price: 980, savedAmount: 420, sortIndex: 2)
        ], selectedID: nil, scope: "all", languageCode: WidgetSnapshotStore.loadLanguageCode())
    }
}

struct SelectJarWishIntent: AppIntent {
    static var title: LocalizedStringResource = "切换心愿"
    static var isDiscoverable = false
    @Parameter(title: "心愿 ID") var itemID: String
    @Parameter(title: "内容分组") var scope: String

    init() { }
    init(id: UUID, scope: String) { itemID = id.uuidString; self.scope = scope }

    func perform() async throws -> some IntentResult {
        let group = scope.hasPrefix("group:") ? String(scope.dropFirst("group:".count)) : nil
        let items = WidgetContentFilter.select(WidgetSnapshotStore.load(), group: group)
        guard let id = UUID(uuidString: itemID), items.contains(where: { $0.id == id }) else { return .result() }
        WishJarState.select(id, scope: scope)
        WidgetCenter.shared.reloadTimelines(ofKind: AwaitGoodsJarWidget.kind)
        return .result()
    }
}

struct AwaitGoodsJarWidget: Widget {
    nonisolated static let kind = "AwaitGoodsJarWidget"
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: Self.kind, intent: WishWidgetConfiguration.self,
                               provider: WishJarProvider()) { entry in
            WishJarWidgetView(entry: entry)
        }
        .configurationDisplayName(NSLocalizedString("JarWidgetName", comment: ""))
        .description(NSLocalizedString("JarWidgetDescription", comment: ""))
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

private struct WishJarWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let content: WishJarContent
    let cards: [WishJarCard]
    let scope: String
    let copy: WidgetCopy

    init(entry: WishJarEntry) {
        content = WishJarContent(items: entry.items, selectedID: entry.selectedID)
        scope = entry.scope
        copy = WidgetCopy(languageCode: entry.languageCode)
        // Share a fixed pixel budget across all photos without excluding any wishes.
        let pixelSize = max(1, min(180, Int(sqrt(1_048_576.0 / Double(max(entry.items.count, 1))))))
        cards = entry.items.map { item in
            WishJarCard(id: item.id, title: item.title, image: Self.thumbnail(for: item, pixelSize: pixelSize))
        }
    }

    private var size: WishJarSize {
        switch family {
        case .systemSmall: return .small
        case .systemLarge: return .large
        default: return .medium
        }
    }

    var body: some View {
        let amounts = size == .medium ? WishJarContent(items: content.focus.map { [$0] } ?? []) : content
        WishJarView(size: size, cards: cards,
                    title: copy.localized("我的心愿罐", "我的心願罐", "My wish jar"),
                    countText: copy.localized("\(content.count) 个心愿", "\(content.count) 個心願",
                                              content.count == 1 ? "1 wish" : "\(content.count) wishes"),
                    savedText: amounts.target > 0 ? "\(copy.savedLabel) \(money(amounts.saved))" : nil,
                    targetText: amounts.target > 0 ? "\(copy.targetLabel) \(money(amounts.target))" : nil,
                    progress: amounts.progress,
                    emptyText: copy.localized("装下第一个心愿", "裝下第一個心願", "Room for your first wish"),
                    appIcon: WidgetImages.appIcon, selectedID: content.focus?.id, navigation: navigation)
            .containerBackground(for: .widget) { WishJarBackground() }
            .widgetURL(size == .medium ? content.focus.map { WishDeepLink.wish($0.id).url } ?? WishDeepLink.home.url : WishDeepLink.home.url)
    }

    private var navigation: some View {
        HStack(spacing: 4) {
            if let previous = content.nextID(direction: -1) {
                Button(intent: SelectJarWishIntent(id: previous, scope: scope)) {
                    WishJarControlLabel(symbol: "chevron.left")
                }
                .accessibilityLabel(copy.localized("上一个心愿", "上一個心願", "Previous wish"))
            }
            Spacer(minLength: 0)
            if size == .medium {
                Text("\(content.position) / \(content.count)")
                    .font(.system(size: 10, weight: .medium).monospacedDigit())
                    .foregroundStyle(WidgetPalette.secondary)
                    .contentTransition(.numericText())
            }
            Spacer(minLength: 0)
            if let next = content.nextID(direction: 1) {
                Button(intent: SelectJarWishIntent(id: next, scope: scope)) {
                    WishJarControlLabel(symbol: "chevron.right")
                }
                .accessibilityLabel(copy.localized("下一个心愿", "下一個心願", "Next wish"))
            }
        }
        .buttonStyle(.plain)
    }

    private func money(_ amount: Double) -> String {
        "$\(amount.formatted(.number.precision(.fractionLength(0))))"
    }

    private static func thumbnail(for item: WishSnapshot, pixelSize: Int) -> Image? {
        guard let filename = item.photoFilename,
              let url = WidgetSnapshotStore.photoURL(filename: filename),
              let source = CGImageSourceCreateWithURL(url as CFURL, [kCGImageSourceShouldCache: false] as CFDictionary),
              let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: pixelSize
              ] as CFDictionary) else { return nil }
        return Image(uiImage: UIImage(cgImage: thumbnail))
    }
}

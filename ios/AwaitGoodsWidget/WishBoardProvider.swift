import AppIntents
import SwiftUI
import WidgetKit

struct WishBoardConfiguration: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "心愿看板"
    static var description = IntentDescription("把心愿、储蓄和冷静期放在桌面。")
    @Parameter(title: "内容分组") var group: WishGroupEntity?
    @Parameter(title: "每次记录金额", default: 50) var depositAmount: Double
    static var parameterSummary: some ParameterSummary { Summary { \.$group; \.$depositAmount } }
    init() { group = .all }
    var scope: String { group?.id ?? "all" }
    var validAmount: Double { depositAmount.isFinite && depositAmount > 0 ? depositAmount : 50 }
}

struct WishBoardEntry: TimelineEntry {
    let date: Date
    let items: [WishSnapshot]
    let selectedID: UUID?
    let scope: String
    let depositAmount: Double
    let languageCode: String
    let feedback: WishBoardFeedback?
    var focus: WishSnapshot? { WishBoardSelection.focus(in: items, selectedID: selectedID) }
}

struct WishBoardProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> WishBoardEntry { preview }

    func snapshot(for configuration: WishBoardConfiguration, in context: Context) async -> WishBoardEntry {
        if context.isPreview && WidgetSnapshotStore.load().isEmpty { return preview }
        return entry(configuration, at: Date())
    }

    func timeline(for configuration: WishBoardConfiguration, in context: Context) async -> Timeline<WishBoardEntry> {
        let now = Date()
        let first = entry(configuration, at: now)
        let refresh = now.addingTimeInterval(1800)
        var dates = first.items.compactMap(\.waitUntil)
        if let feedback = first.feedback { dates.append(feedback.date.addingTimeInterval(300)) }
        let transitions = Array(Set(dates.filter { $0 > now && $0 < refresh })).sorted()
        return Timeline(entries: [first] + transitions.map { entry(configuration, at: $0) }, policy: .after(refresh))
    }

    private func entry(_ configuration: WishBoardConfiguration, at date: Date) -> WishBoardEntry {
        let feedback = WishBoardState.feedback(scope: configuration.scope)
        return WishBoardEntry(date: date,
                              items: WidgetContentFilter.select(WidgetSnapshotStore.load(), group: configuration.group?.group),
                              selectedID: WishBoardState.selection(scope: configuration.scope), scope: configuration.scope,
                              depositAmount: configuration.validAmount, languageCode: WidgetSnapshotStore.loadLanguageCode(),
                              feedback: feedback?.isVisible(at: date) == true ? feedback : nil)
    }

    private var preview: WishBoardEntry {
        let now = Date()
        let items = [
            WishSnapshot(id: UUID(), title: "Travel camera", price: 980, savedAmount: 720, sortIndex: 0,
                         updatedAt: now, waitUntil: now.addingTimeInterval(86400 * 2)),
            WishSnapshot(id: UUID(), title: "Weekend bag", price: 1200, savedAmount: 800, sortIndex: 1, updatedAt: now),
            WishSnapshot(id: UUID(), title: "Classic watch", price: 2400, savedAmount: 1800, sortIndex: 2, updatedAt: now)
        ]
        return WishBoardEntry(date: now, items: items, selectedID: nil, scope: "all", depositAmount: 50,
                              languageCode: WidgetSnapshotStore.loadLanguageCode(), feedback: nil)
    }
}

struct SelectBoardWishIntent: AppIntent {
    static var title: LocalizedStringResource = "切换心愿"
    static var isDiscoverable = false
    @Parameter(title: "心愿 ID") var itemID: String
    @Parameter(title: "内容分组") var scope: String

    init() { }
    init(id: UUID, scope: String) { itemID = id.uuidString; self.scope = scope }

    func perform() async throws -> some IntentResult {
        guard let id = UUID(uuidString: itemID), WidgetSnapshotStore.load().contains(where: { $0.id == id }) else {
            return .result()
        }
        WishBoardState.select(id, scope: scope)
        WidgetCenter.shared.reloadTimelines(ofKind: AwaitGoodsBoardWidget.kind)
        return .result()
    }
}

struct AwaitGoodsBoardWidget: Widget {
    nonisolated static let kind = "AwaitGoodsBoardWidget"

    private var families: [WidgetFamily] {
        // Xcode 27 ships Swift 6.4 and the SDK that exposes this family on iOS.
        #if compiler(>=6.4)
        if #available(iOS 27.0, *) { return [.systemLarge, .systemExtraLarge, .systemExtraLargePortrait] }
        #endif
        return [.systemLarge, .systemExtraLarge]
    }

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: Self.kind, intent: WishBoardConfiguration.self, provider: WishBoardProvider()) { entry in
            WishBoardView(entry: entry)
        }
        .configurationDisplayName(NSLocalizedString("BoardWidgetName", comment: ""))
        .description(NSLocalizedString("BoardWidgetDescription", comment: ""))
        .supportedFamilies(families)
    }
}

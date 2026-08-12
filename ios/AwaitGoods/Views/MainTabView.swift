import SwiftData
import SwiftUI

struct MainTabView: View {
    @Binding var selection: MainTab
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: [SortDescriptor(\WishItem.sortIndex), SortDescriptor(\WishItem.createdAt, order: .reverse)]) private var items: [WishItem]
    @AppStorage("appLanguage") private var appLanguageRawValue = AppLanguage.zhHans.rawValue
    @AppStorage(AppTheme.storageKey) private var appThemeRawValue = AppTheme.springPaper.rawValue

    private var appLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguageRawValue) ?? .zhHans
    }

    var body: some View {
        TabView(selection: $selection) {
            WishListView()
                .tabItem {
                    Label(appLanguage.text("候物"), systemImage: "bag")
                }
                .tag(MainTab.wishList)

            StatsView()
                .tabItem {
                    Label(appLanguage.text("统计"), systemImage: "chart.bar.xaxis")
                }
                .tag(MainTab.statistics)

            SettingsView(items: items) {
                WidgetSyncService.sync(items: items)
            }
            .tabItem {
                Label(appLanguage.text("设置"), systemImage: "gearshape")
            }
            .tag(MainTab.settings)
        }
        .environment(\.appLanguage, appLanguage)
        .tint(HWTheme.freshGreen)
        .toolbarBackground(HWTheme.pageBackground, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .background(HWTheme.pageBackground.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.2), value: appThemeRawValue)
        .onAppear {
            WidgetSyncService.sync(items: items)
            Task { await NotificationScheduler.synchronize(items: items) }
        }
        .onChange(of: widgetSyncSignature) { _, _ in
            WidgetSyncService.sync(items: items)
        }
        .onChange(of: appLanguageRawValue) { _, _ in
            WidgetSyncService.sync(items: items)
            Task { await NotificationScheduler.synchronize(items: items) }
        }
        .onChange(of: notificationSyncSignature) { _, _ in
            Task { await NotificationScheduler.synchronize(items: items) }
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task { await NotificationScheduler.synchronize(items: items) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openAwaitGoodsWishList)) { _ in
            selection = .wishList
        }
    }

    private var widgetSyncSignature: [String] {
        items.map { item in
            [
                item.id.uuidString,
                item.title,
                item.statusRawValue,
                String(item.sortIndex),
                String(item.price ?? 0),
                String(item.savedAmountValue),
                String(item.updatedAt.timeIntervalSince1970)
            ].joined(separator: "|")
        }
    }

    private var notificationSyncSignature: [String] {
        items.map { item in
            [
                item.id.uuidString,
                item.title,
                item.category,
                String(item.priorityRawValue),
                item.statusRawValue,
                String(item.price ?? 0),
                String(item.savedAmountValue),
                String(item.notifyEnabled),
                String(item.targetDate?.timeIntervalSince1970 ?? 0),
                String(item.waitUntil?.timeIntervalSince1970 ?? 0),
                String(item.isTrashed)
            ].joined(separator: "|")
        }
    }
}

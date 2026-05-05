import SwiftData
import SwiftUI

struct MainTabView: View {
    @Query(sort: [SortDescriptor(\WishItem.sortIndex), SortDescriptor(\WishItem.createdAt, order: .reverse)]) private var items: [WishItem]
    @AppStorage("appLanguage") private var appLanguageRawValue = AppLanguage.zhHans.rawValue
    @AppStorage(AppTheme.storageKey) private var appThemeRawValue = AppTheme.springPaper.rawValue

    private var appLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguageRawValue) ?? .zhHans
    }

    var body: some View {
        TabView {
            WishListView()
                .tabItem {
                    Label(appLanguage.text("候物"), systemImage: "bag")
                }

            SettingsView(items: items) {
                WidgetSyncService.sync(items: items)
            }
            .tabItem {
                Label(appLanguage.text("设置"), systemImage: "gearshape")
            }
        }
        .environment(\.appLanguage, appLanguage)
        .tint(HWTheme.freshGreen)
        .toolbarBackground(HWTheme.pageBackground, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .background(HWTheme.pageBackground.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.2), value: appThemeRawValue)
        .onAppear {
            WidgetSyncService.sync(items: items)
        }
        .onChange(of: widgetSyncSignature) { _, _ in
            WidgetSyncService.sync(items: items)
        }
        .onChange(of: appLanguageRawValue) { _, _ in
            WidgetSyncService.sync(items: items)
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
}
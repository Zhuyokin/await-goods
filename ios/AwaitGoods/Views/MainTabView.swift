import SwiftData
import SwiftUI

struct MainTabView: View {
    @Query(sort: [SortDescriptor(\WishItem.sortIndex), SortDescriptor(\WishItem.createdAt, order: .reverse)]) private var items: [WishItem]
    @AppStorage("appLanguage") private var appLanguageRawValue = AppLanguage.zhHans.rawValue

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
    }
}
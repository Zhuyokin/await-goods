import SwiftData
import SwiftUI

struct MainTabView: View {
    @Query(sort: [SortDescriptor(\WishItem.sortIndex), SortDescriptor(\WishItem.createdAt, order: .reverse)]) private var items: [WishItem]

    var body: some View {
        TabView {
            WishListView()
                .tabItem {
                    Label("候物", systemImage: "leaf")
                }

            SettingsView(items: items) {
                WidgetSyncService.sync(items: items)
            }
            .tabItem {
                Label("设置", systemImage: "slider.horizontal.3")
            }
        }
        .tint(HWTheme.freshGreen)
        .toolbarBackground(HWTheme.pageBackground, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .background(HWTheme.pageBackground.ignoresSafeArea())
    }
}
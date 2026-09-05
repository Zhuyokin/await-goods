import SwiftData
import SwiftUI

struct MainTabView: View {
    @Binding var selection: MainTab
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: [SortDescriptor(\WishItem.sortIndex), SortDescriptor(\WishItem.createdAt, order: .reverse)]) private var items: [WishItem]
    @AppStorage("appLanguage") private var appLanguageRawValue = AppLanguage.zhHans.rawValue
    @AppStorage(AppTheme.storageKey) private var appThemeRawValue = AppTheme.springPaper.rawValue
    @State private var splitViewVisibility: NavigationSplitViewVisibility = .all

    private var appLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguageRawValue) ?? .zhHans
    }

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                tabletSplitView
            } else {
                phoneTabs
            }
        }
        .environment(\.appLanguage, appLanguage)
        .tint(HWTheme.freshGreen)
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

    private var phoneTabs: some View {
        TabView(selection: $selection) {
            ForEach(tabs, id: \.self) { tab in
                rootView(for: tab)
                    .tabItem {
                        Label(appLanguage.text(tab.titleKey), systemImage: tab.iconName)
                    }
                    .tag(tab)
            }
        }
        .toolbarBackground(HWTheme.pageBackground, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }

    private var tabletSplitView: some View {
        NavigationSplitView(columnVisibility: $splitViewVisibility) {
            List {
                Section {
                    ForEach(tabs, id: \.self) { tab in
                        Button {
                            selection = tab
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: tab.iconName)
                                    .frame(width: 18, height: 18)

                                Text(appLanguage.text(tab.titleKey))
                                    .font(.system(size: 15, weight: selection == tab ? .semibold : .regular))

                                Spacer()
                            }
                            .foregroundStyle(selection == tab ? HWTheme.freshGreen : HWTheme.primaryText)
                            .padding(.horizontal, 10)
                            .frame(height: 42)
                            .background(selection == tab ? HWTheme.mint.opacity(0.28) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(selection == tab ? .isSelected : [])
                    }
                }

                Section {
                    HStack(spacing: 10) {
                        AppLogoMark(size: 34, cornerRadius: 9)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(appLanguage.text("候物"))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(HWTheme.primaryText)

                            Text(appLanguage.text("极简愿望清单与购物清单"))
                                .font(.system(size: 9))
                                .foregroundStyle(HWTheme.secondaryText)
                                .lineLimit(2)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            .background(HWTheme.listBackground)
            .navigationTitle(appLanguage.text("候物"))
            .navigationSplitViewColumnWidth(min: 210, ideal: 240, max: 280)
        } detail: {
            rootView(for: selection)
                .id(selection)
        }
        .navigationSplitViewStyle(.balanced)
    }

    @ViewBuilder
    private func rootView(for tab: MainTab) -> some View {
        switch tab {
        case .wishList:
            WishListView()
        case .statistics:
            StatsView()
        case .settings:
            SettingsView(items: items) {
                WidgetSyncService.sync(items: items)
            }
        }
    }

    private var tabs: [MainTab] {
        [.wishList, .statistics, .settings]
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

private extension MainTab {
    var titleKey: String {
        switch self {
        case .wishList: return "候物"
        case .statistics: return "统计"
        case .settings: return "设置"
        }
    }

    var iconName: String {
        switch self {
        case .wishList: return "bag"
        case .statistics: return "chart.bar.xaxis"
        case .settings: return "gearshape"
        }
    }
}

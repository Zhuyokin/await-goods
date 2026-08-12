import SwiftData
import SwiftUI

enum MainTab: Hashable {
    case wishList
    case statistics
    case settings
}

@main
struct AwaitGoodsApp: App {
    @AppStorage("appearanceMode") private var appearanceMode = AppAppearanceMode.system.rawValue
    @AppStorage("appLanguage") private var appLanguageRawValue = AppLanguage.zhHans.rawValue
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage(AppTheme.storageKey) private var appThemeRawValue = AppTheme.springPaper.rawValue
    @State private var selectedTab: MainTab = .wishList

    private var appLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguageRawValue) ?? .zhHans
    }

    private let modelContainer: ModelContainer = {
        let schema = Schema([WishItem.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Unable to create SwiftData container: \(error)")
        }
    }()

    init() {
        NotificationScheduler.configure()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if hasSeenOnboarding {
                    MainTabView(selection: $selectedTab)
                } else {
                    OnboardingView {
                        hasSeenOnboarding = true
                    }
                }
            }
                .environment(\.appLanguage, appLanguage)
                .tint(HWTheme.freshGreen)
                .preferredColorScheme(AppAppearanceMode(rawValue: appearanceMode)?.colorScheme)
                .animation(.easeInOut(duration: 0.2), value: appThemeRawValue)
                .onOpenURL(perform: handleIncomingURL)
                #if DEBUG
                .task {
                    ScreenshotSeedService.seedIfNeeded(in: modelContainer)
                }
                #endif
        }
        .modelContainer(modelContainer)
    }

    private func handleIncomingURL(_ url: URL) {
        guard url.scheme?.lowercased() == "https",
              url.host?.lowercased() == "app-privacy-support.pages.dev"
        else { return }

        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        switch path {
        case "AwaitGoods/data-static", "AwaitGoods/data-static-act":
            selectedTab = .statistics
        default:
            break
        }
    }
}

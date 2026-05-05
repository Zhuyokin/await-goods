import SwiftData
import SwiftUI

@main
struct AwaitGoodsApp: App {
    @AppStorage("appearanceMode") private var appearanceMode = AppAppearanceMode.system.rawValue
    @AppStorage("appLanguage") private var appLanguageRawValue = AppLanguage.zhHans.rawValue
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage(AppTheme.storageKey) private var appThemeRawValue = AppTheme.springPaper.rawValue

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

    var body: some Scene {
        WindowGroup {
            Group {
                if hasSeenOnboarding {
                    MainTabView()
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
                #if DEBUG
                .task {
                    ScreenshotSeedService.seedIfNeeded(in: modelContainer)
                }
                #endif
        }
        .modelContainer(modelContainer)
    }
}

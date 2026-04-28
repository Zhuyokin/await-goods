import SwiftData
import SwiftUI

@main
struct AwaitGoodsApp: App {
    @AppStorage("appearanceMode") private var appearanceMode = AppAppearanceMode.system.rawValue

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
            MainTabView()
                .preferredColorScheme(AppAppearanceMode(rawValue: appearanceMode)?.colorScheme)
                #if DEBUG
                .task {
                    ScreenshotSeedService.seedIfNeeded(in: modelContainer)
                }
                #endif
        }
        .modelContainer(modelContainer)
    }
}

import SwiftData

@MainActor
enum AppWishStore {
    static let container: ModelContainer = {
        let schema = Schema([WishItem.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Unable to create SwiftData container: \(error)")
        }
    }()
}

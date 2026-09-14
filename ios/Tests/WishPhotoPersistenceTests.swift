import Foundation
import SwiftData

@main
struct WishPhotoPersistenceTests {
    @MainActor
    static func main() throws {
        let container = try ModelContainer(for: WishItem.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let data = Data([0xFF, 0xD8, 0xFF, 0xD9])
        let photoItem = WishItem(title: "With photo", photoData: data)
        container.mainContext.insert(photoItem)
        container.mainContext.insert(WishItem(title: "Without photo"))
        try container.mainContext.save()
        let context = ModelContext(container)
        let loaded = try context.fetch(FetchDescriptor<WishItem>())
        precondition(loaded.first { $0.title == "With photo" }?.photoData == data)
        precondition(loaded.first { $0.title == "Without photo" }?.photoData == nil)
        print("Wish photo persistence checks passed")
    }
}

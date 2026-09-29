import Foundation
import SwiftData

@main
struct LegacyCurrencyStore {
    @MainActor static func main() throws {
        let url = URL(fileURLWithPath: CommandLine.arguments[1])
        let container = try ModelContainer(for: WishItem.self, configurations: ModelConfiguration(url: url))
        let item = WishItem(id: UUID(uuidString: "B106A091-1D45-4998-A6A2-D7C55B2BFF61")!, title: "Legacy camera", price: 1234.5,
                            isPinned: true, savedAmount: 234.25, photoData: Data([1, 2, 3]))
        container.mainContext.insert(item)
        try container.mainContext.save()
    }
}

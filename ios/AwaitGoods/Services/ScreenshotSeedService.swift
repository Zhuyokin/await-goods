#if DEBUG
import Foundation
import SwiftData

@MainActor
enum ScreenshotSeedService {
    static let isEnabled = true
    private static let replacesExistingData = true

    static func seedIfNeeded(in container: ModelContainer) {
        guard isEnabled else { return }

        let context = ModelContext(container)
        let descriptor = FetchDescriptor<WishItem>()
        let existingItems = (try? context.fetch(descriptor)) ?? []

        if replacesExistingData {
            existingItems.forEach { context.delete($0) }
        } else if !existingItems.isEmpty {
            return
        }

        let seededItems = screenshotItems()
        seededItems.forEach { context.insert($0) }
        try? context.save()
        WidgetSyncService.sync(items: seededItems)
    }

    private static func screenshotItems() -> [WishItem] {
        let now = Date()
        let day: TimeInterval = 24 * 60 * 60

        return seedWishes.enumerated().map { index, seed in
            WishItem(
                title: seed.title,
                price: seed.price,
                linkString: seed.linkString,
                note: seed.note,
                category: seed.category,
                priority: seed.priority,
                status: seed.status,
                markColor: seed.markColor,
                sortIndex: index,
                createdAt: now.addingTimeInterval(-Double(index + 1) * day),
                updatedAt: now.addingTimeInterval(-Double(index % 9) * day),
                savedAmount: seed.savedAmount,
                photoData: seed.photoData
            )
        }
    }

    private struct SeedWish {
        let title: String
        let price: Double
        let linkString: String
        let note: String
        let category: String
        let priority: WishPriority
        let status: WishItemStatus
        let markColor: MarkColor
        let savedAmount: Double
        let imageName: String

        var photoData: Data {
            guard let url = Bundle.main.url(forResource: imageName, withExtension: nil, subdirectory: "DebugSeedImages"),
                  let data = try? Data(contentsOf: url) else {
                preconditionFailure("Missing debug wish image: \(imageName)")
            }
            return data
        }
    }

    private static let seedWishes: [SeedWish] = [
        SeedWish(title: "Louis Vuitton Neverfull MM", price: 2240, linkString: "https://us.louisvuitton.com/eng-us/products/neverfull-mm-monogram-nvprod5350101v/M46975", note: "An everyday tote for work and weekend trips.", category: "Luxury Bags", priority: .high, status: .waiting, markColor: .green, savedAmount: 820, imageName: "lv-neverfull.png"),
        SeedWish(title: "Louis Vuitton Alma BB", price: 2000, linkString: "https://us.louisvuitton.com/eng-us/products/alma-bb-monogram-nvprod5190086v/M46990", note: "A compact classic for dinners and city days.", category: "Luxury Bags", priority: .medium, status: .waiting, markColor: .pink, savedAmount: 430, imageName: "lv-alma.png"),
        SeedWish(title: "Louis Vuitton OnTheGo MM", price: 3400, linkString: "https://us.louisvuitton.com/eng-us/products/onthego-mm-monogram-nvprod2130189v/M45321", note: "Room for a laptop and daily essentials.", category: "Luxury Bags", priority: .medium, status: .waiting, markColor: .yellow, savedAmount: 1180, imageName: "lv-onthego.png"),
        SeedWish(title: "Rolex Submariner Date", price: 11350, linkString: "https://www.rolex.com/en-us/watches/submariner/m126610ln-0001", note: "Black dial and Oystersteel bracelet.", category: "Watches", priority: .high, status: .waiting, markColor: .green, savedAmount: 3100, imageName: "rolex-submariner.jpg"),
        SeedWish(title: "Rolex Datejust 36", price: 10000, linkString: "https://www.rolex.com/en-us/watches/datejust/m126234-0051", note: "Mint green dial with a Jubilee bracelet.", category: "Watches", priority: .high, status: .waiting, markColor: .yellow, savedAmount: 2400, imageName: "rolex-datejust.jpg"),
        SeedWish(title: "Rolex Lady-Datejust 28", price: 11900, linkString: "https://www.rolex.com/en-us/watches/lady-datejust/m279174-0009", note: "Mother-of-pearl dial for special occasions.", category: "Watches", priority: .medium, status: .waiting, markColor: .pink, savedAmount: 1740, imageName: "rolex-lady-datejust.jpg"),
        SeedWish(title: "Porsche 911 Carrera", price: 135000, linkString: "https://www.porsche.com/usa/models/911/carrera-models/911-carrera/", note: "A dream sports car for weekend road trips.", category: "Luxury Cars", priority: .high, status: .waiting, markColor: .green, savedAmount: 32000, imageName: "porsche-911.png"),
        SeedWish(title: "Bentley Continental GT Speed", price: 300000, linkString: "https://www.bentleymotors.com/en/models/continental-gt.html", note: "A grand tourer for long-distance comfort.", category: "Luxury Cars", priority: .medium, status: .waiting, markColor: .gray, savedAmount: 58000, imageName: "bentley-continental.jpg"),
        SeedWish(title: "Lamborghini Revuelto", price: 608000, linkString: "https://www.lamborghini.com/en-en/models/revuelto", note: "A long-term supercar dream.", category: "Luxury Cars", priority: .medium, status: .waiting, markColor: .yellow, savedAmount: 86000, imageName: "lamborghini-revuelto.jpg"),
        SeedWish(title: "Apple iPhone 17e", price: 599, linkString: "https://www.apple.com/iphone-17e/", note: "A19 performance with MagSafe for everyday use.", category: "Apple", priority: .high, status: .waiting, markColor: .pink, savedAmount: 320, imageName: "apple-iphone.png"),
        SeedWish(title: "Apple MacBook Air 13-inch M5", price: 1099, linkString: "https://www.apple.com/macbook-air/", note: "A lightweight laptop for work and travel.", category: "Apple", priority: .high, status: .waiting, markColor: .green, savedAmount: 680, imageName: "apple-macbook.png"),
        SeedWish(title: "Apple iPad Air 11-inch M4", price: 599, linkString: "https://www.apple.com/ipad-air/", note: "A portable canvas for reading and sketching.", category: "Apple", priority: .medium, status: .waiting, markColor: .yellow, savedAmount: 260, imageName: "apple-ipad.png"),
    ]
}
#endif

import Foundation

enum WishStatisticsTests {
    static func run() {
        let items = [
            WishItem(title: "Bag", price: 200, category: "衣物", savedAmount: 50),
            WishItem(title: "Shoes", price: 100, category: " 衣物 ", savedAmount: 150),
            WishItem(title: "Undecided", savedAmount: 500),
            WishItem(title: "Zero target", price: 0),
            WishItem(title: "Owned", price: 800, status: .bought, savedAmount: 800),
            WishItem(title: "Released", price: 900, status: .released, savedAmount: 100),
            WishItem(title: "Deleted", price: 1000, savedAmount: 100, trashedAt: Date())
        ]
        let stats = WishStatistics(items: items)
        precondition(stats.activeItems.count == 6, "Trash must not enter statistics")
        precondition(stats.waitingItems.count == 4)
        precondition(stats.budget == 300, "Only priced waiting items belong to the savings goal")
        precondition(stats.saved == 150, "Unpriced, owned and released savings must not inflate progress")
        precondition(stats.remaining == 150)
        precondition(stats.progress == 0.5)
        precondition(stats.unpricedCount == 2)
        precondition(stats.items(for: .bought).count == 1)
        precondition(stats.items(for: .released).count == 1)
        precondition(stats.categories.first { $0.name == "衣物" }?.count == 2)
        precondition(stats.categories.first { $0.name.isEmpty }?.count == 2)

        let empty = WishStatistics(items: [])
        precondition(empty.budget == 0 && empty.saved == 0 && empty.remaining == 0)
        precondition(empty.progress == 0 && empty.categories.isEmpty)
        let unpriced = WishStatistics(items: [WishItem(title: "Trip", savedAmount: 80)])
        precondition(unpriced.progress == 0 && unpriced.saved == 0 && unpriced.unpricedCount == 1)
        let complete = WishStatistics(items: [WishItem(title: "Book", price: 20, savedAmount: 30)])
        precondition(complete.progress == 1 && complete.remaining == 0)
        print("Wish statistics checks passed")
    }
}

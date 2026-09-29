import Foundation
import SwiftData

enum WishListOrderingTests {
    @MainActor
    static func run() throws {
        let first = WishItem(title: "First", price: 100, sortIndex: 0, createdAt: Date(timeIntervalSince1970: 10), savedAmount: 10)
        let second = WishItem(title: "Second", price: 300, sortIndex: 1, createdAt: Date(timeIntervalSince1970: 20), savedAmount: 240)
        let third = WishItem(title: "Third", price: 200, sortIndex: 2, createdAt: Date(timeIntervalSince1970: 30), savedAmount: 100)
        third.isPinned = true
        let items = [first, second, third]
        precondition(WishSortIndexPolicy.sorted(items, by: .manual).map(\.title) == ["Third", "First", "Second"])
        precondition(WishSortIndexPolicy.sorted(items, by: .priceHigh).map(\.title) == ["Third", "Second", "First"])
        precondition(WishSortIndexPolicy.sorted(items, by: .savings).map(\.title) == ["Third", "Second", "First"])
        precondition(WishSortIndexPolicy.sorted([first, second], by: .recent).map(\.title) == ["Second", "First"],
                     "A pinned wish outside the current results must not reappear")
        first.isPinned = true
        precondition(WishSortIndexPolicy.sorted(items, by: .recent).map(\.title) == ["Third", "First", "Second"])
        third.isPinned = false
        first.isPinned = false
        precondition(WishSortIndexPolicy.sorted(items, by: .manual).map(\.title) == ["First", "Second", "Third"],
                     "Unpinning must restore the chosen ordering without changing sort indices")
        precondition(WishSortIndexPolicy.sorted(items, by: .manual, manualOrder: [third.id, first.id, second.id]).map(\.title) == ["Third", "First", "Second"])
        let container = try ModelContainer(for: WishItem.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        third.isPinned = true
        container.mainContext.insert(third)
        try container.mainContext.save()
        let restored = try ModelContext(container).fetch(FetchDescriptor<WishItem>()).first!
        precondition(restored.isPinned && restored.sortIndex == 2, "Pinning persists independently from manual ordering")
        print("Wish list pinning, sorting and persistence checks passed")
    }
}

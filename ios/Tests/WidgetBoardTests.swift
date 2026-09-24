import Foundation
import SwiftData

enum WidgetBoardTests {
    @MainActor
    static func run() throws {
        let container = try ModelContainer(for: WishItem.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        let before = Date(timeIntervalSince1970: 1000)
        let after = before.addingTimeInterval(1)
        let item = WishItem(title: "Camera", price: 100, updatedAt: before, savedAmount: 80)
        context.insert(item)
        try context.save()

        let receipt = try WidgetSavingsMutation.deposit(item, amount: 50, expectedUpdatedAt: before, at: after)
        try context.save()
        let loaded = try ModelContext(container).fetch(FetchDescriptor<WishItem>()).first!
        precondition(loaded.savedAmountValue == 100 && loaded.status == .bought)
        precondition(receipt.amount == 20, "Record only the amount still needed")
        expectFailure { _ = try WidgetSavingsMutation.deposit(item, amount: 50, expectedUpdatedAt: before) }
        precondition(item.savedAmountValue == 100, "Replayed widget taps must not deposit twice")

        let restoredReceipt = try JSONDecoder().decode(WidgetSavingsReceipt.self, from: JSONEncoder().encode(receipt))
        try WidgetSavingsMutation.undo(item, receipt: restoredReceipt, at: after.addingTimeInterval(1))
        try context.save()
        precondition(item.savedAmountValue == 80 && item.status == .waiting)
        expectFailure { try WidgetSavingsMutation.undo(item, receipt: restoredReceipt) }

        for amount in [0, -1, Double.infinity, Double.nan] {
            expectFailure { _ = try WidgetSavingsMutation.deposit(item, amount: amount, expectedUpdatedAt: item.updatedAt) }
        }
        let staleReceipt = try WidgetSavingsMutation.deposit(item, amount: 5, expectedUpdatedAt: item.updatedAt, at: after.addingTimeInterval(3))
        item.savedAmountValue = 90
        expectFailure { try WidgetSavingsMutation.undo(item, receipt: staleReceipt) }
        precondition(item.savedAmountValue == 90, "Undo must preserve subsequent app edits")
        item.moveToTrash()
        expectFailure { _ = try WidgetSavingsMutation.deposit(item, amount: 5, expectedUpdatedAt: item.updatedAt) }
        let unpriced = WishItem(title: "Undecided")
        expectFailure { _ = try WidgetSavingsMutation.deposit(unpriced, amount: 5, expectedUpdatedAt: unpriced.updatedAt) }

        let first = WishSnapshot(id: UUID(), title: "A", price: 100, sortIndex: 0, updatedAt: before, waitUntil: after)
        let second = WishSnapshot(id: UUID(), title: "B", price: 0, sortIndex: 1)
        precondition(WishBoardSelection.focus(in: [first, second], selectedID: UUID())?.id == first.id)
        precondition(WishBoardSelection.next(in: [first, second], currentID: second.id, direction: 1) == first.id)
        precondition(WishBoardSelection.next(in: [first, second], currentID: first.id, direction: -1) == second.id)
        precondition(WishBoardSelection.next(in: [], currentID: nil, direction: 1) == nil)
        let snapshot = try JSONDecoder().decode(WishSnapshot.self, from: JSONEncoder().encode(first))
        precondition(snapshot.waitUntil == after && snapshot.updatedAt == before)
        precondition(WishDeepLink(url: WishDeepLink.wish(first.id).url) == .wish(first.id))
        precondition(WishDeepLink(url: URL(string: "awaitgoods://wish/not-a-uuid")!) == nil)
        precondition(WishDeepLink(url: URL(string: "https://wish/\(first.id)")!) == nil)
        print("Widget board mutation, persistence, selection and routing checks passed")
        let jarItems = (0..<8).map { index in
            WishSnapshot(id: UUID(), title: "Wish \(index)", price: 100,
                         savedAmount: index == 0 ? 150 : 25, sortIndex: index)
        }
        let jar = WishJarContent(items: jarItems)
        precondition(jar.displayItems.map(\.id) == jarItems.map(\.id), "Every wish must appear in order")
        precondition(jar.count == 8 && jar.target == 800 && jar.saved == 275,
                     "Totals must include every wish and cap each deposit at its target")
        let unpricedJar = WishJarContent(items: [second])
        precondition(unpricedJar.target == 0 && unpricedJar.progress == 0 && unpricedJar.count == 1)
        let emptyJar = WishJarContent(items: [])
        precondition(emptyJar.displayItems.isEmpty && emptyJar.progress == 0)
        let invalidJar = WishJarContent(items: [
            WishSnapshot(id: UUID(), title: "Invalid", price: .infinity, savedAmount: 100, sortIndex: 0),
            WishSnapshot(id: UUID(), title: "Negative", price: 100, savedAmount: -10, sortIndex: 1),
            WishSnapshot(id: UUID(), title: "Unknown", price: 100, savedAmount: .nan, sortIndex: 2)
        ])
        precondition(invalidJar.target == 200 && invalidJar.saved == 0 && invalidJar.progress == 0)
        let selectedJar = WishJarContent(items: jarItems, selectedID: jarItems[6].id)
        precondition(selectedJar.focus?.id == jarItems[6].id && selectedJar.position == 7)
        precondition(selectedJar.focus?.savedAmount == 25 && selectedJar.count == 8)
        precondition(selectedJar.nextID(direction: 1) == jarItems[7].id)
        precondition(WishJarContent(items: jarItems, selectedID: jarItems.last!.id).nextID(direction: 1) == jarItems.first!.id)
        precondition(jar.nextID(direction: -1) == jarItems.last!.id)
        precondition(emptyJar.nextID(direction: 1) == nil)
        precondition(WishJarContent(items: jarItems, selectedID: UUID()).focus?.id == jarItems.first!.id)
        for count in [8, 40, 100] {
            let poses = (0..<count).map { WishJarLayout.pose(index: $0, count: count) }
            precondition(poses.count == count)
            precondition(zip(poses, poses.dropFirst()).contains { a, b in
                abs(a.x - b.x) < (a.width + b.width) / 2 && abs(a.y - b.y) < (a.width + b.width) * 0.59
            }, "Cards must overlap even in large collections")
            precondition(poses.allSatisfy { $0.width >= 42 && $0.x > 60 && $0.x < 180 && $0.y > 110 && $0.y < 230 })
        }
        print("Wish jar selection, totals and empty-state checks passed")
    }

    private static func expectFailure(_ action: () throws -> Void) {
        do {
            try action()
            preconditionFailure("Stale or invalid widget action must be rejected")
        } catch { }
    }
}

import AppIntents
import Foundation
import SwiftData

// ForegroundContinuableIntent executes in the app process; no foreground request is needed.
extension RecordWishSavingsIntent: ForegroundContinuableIntent { }
extension UndoWishSavingsIntent: ForegroundContinuableIntent { }

@MainActor
enum WidgetActionService {
    static func deposit(itemID: String, amount: Double, revision: Double, scope: String) async {
        let context = AppWishStore.container.mainContext
        do {
            let items = try context.fetch(FetchDescriptor<WishItem>())
            guard let item = items.first(where: { $0.id.uuidString == itemID }) else {
                throw WidgetSavingsError.unavailable
            }
            let receipt = try WidgetSavingsMutation.deposit(item, amount: amount,
                                                           expectedUpdatedAt: Date(timeIntervalSince1970: revision))
            do { try context.save() } catch { context.rollback(); throw error }
            WishBoardState.saveFeedback(WishBoardFeedback(outcome: .saved, receipt: receipt), scope: scope)
            WidgetSyncService.sync(items: items)
            if item.status == .bought { NotificationScheduler.cancel(for: item) }
        } catch {
            report(error, scope: scope, context: context)
        }
    }

    static func undo(receiptID: String, scope: String) async {
        let context = AppWishStore.container.mainContext
        do {
            let items = try context.fetch(FetchDescriptor<WishItem>())
            guard let feedback = WishBoardState.feedback(scope: scope), feedback.isVisible(at: Date()),
                  feedback.outcome == .saved, let receipt = feedback.receipt,
                  receipt.id.uuidString == receiptID,
                  let item = items.first(where: { $0.id == receipt.itemID }) else {
                throw WidgetSavingsError.stale
            }
            try WidgetSavingsMutation.undo(item, receipt: receipt)
            do { try context.save() } catch { context.rollback(); throw error }
            WishBoardState.saveFeedback(WishBoardFeedback(outcome: .undone, receipt: nil), scope: scope)
            WishBoardState.select(item.id, scope: scope)
            WidgetSyncService.sync(items: items)
            await NotificationScheduler.schedule(for: item)
        } catch {
            report(error, scope: scope, context: context)
        }
    }

    private static func report(_ error: Error, scope: String, context: ModelContext) {
        let outcome: WishBoardFeedback.Outcome = error is WidgetSavingsError ? .stale : .failed
        let items = try? context.fetch(FetchDescriptor<WishItem>())
        let previous = WishBoardState.feedback(scope: scope)
        // Duplicate taps should leave a successful record available to undo.
        let hasCurrentReceipt = previous?.outcome == .saved && previous?.isVisible(at: Date()) == true &&
            items?.contains(where: { item in
                guard let receipt = previous?.receipt else { return false }
                return item.id == receipt.itemID && !item.isTrashed && item.updatedAt == receipt.updatedAt
            }) == true
        if !hasCurrentReceipt {
            WishBoardState.saveFeedback(WishBoardFeedback(outcome: outcome, receipt: nil), scope: scope)
        }
        if let items { WidgetSyncService.sync(items: items) }
    }
}

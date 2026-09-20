import Foundation

enum WidgetSavingsError: Error { case invalidAmount, unavailable, stale }

enum WidgetSavingsMutation {
    static func deposit(_ item: WishItem, amount: Double, expectedUpdatedAt: Date, at date: Date = Date()) throws -> WidgetSavingsReceipt {
        guard amount.isFinite, amount > 0 else { throw WidgetSavingsError.invalidAmount }
        guard !item.isTrashed, item.status == .waiting,
              let target = item.savingsTarget, target.isFinite,
              item.savedAmountValue.isFinite, item.savedAmountValue < target else {
            throw WidgetSavingsError.unavailable
        }
        guard abs(item.updatedAt.timeIntervalSince(expectedUpdatedAt)) < 0.000001 else {
            throw WidgetSavingsError.stale
        }
        let previous = item.savedAmount
        let previousStatus = item.statusRawValue
        let credited = min(amount, target - item.savedAmountValue)
        item.savedAmountValue += credited
        item.reconcileSavingsStatus()
        // A new revision also rejects repeat taps if the wall clock moves backwards.
        item.updatedAt = max(date, expectedUpdatedAt.addingTimeInterval(0.001))
        return WidgetSavingsReceipt(id: UUID(), itemID: item.id, title: item.title,
                                    previousSavedAmount: previous, previousStatus: previousStatus,
                                    savedAmount: item.savedAmountValue, status: item.statusRawValue,
                                    updatedAt: item.updatedAt, amount: credited)
    }

    static func undo(_ item: WishItem, receipt: WidgetSavingsReceipt, at date: Date = Date()) throws {
        guard item.id == receipt.itemID, !item.isTrashed,
              abs(item.updatedAt.timeIntervalSince(receipt.updatedAt)) < 0.000001,
              item.savedAmountValue == receipt.savedAmount, item.statusRawValue == receipt.status else {
            throw WidgetSavingsError.stale
        }
        item.savedAmount = receipt.previousSavedAmount
        item.statusRawValue = receipt.previousStatus
        item.updatedAt = max(date, receipt.updatedAt.addingTimeInterval(0.001))
    }
}

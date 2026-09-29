import Foundation

struct WishStatistics {
    let activeItems: [WishItem]
    let waitingItems: [WishItem]
    let budget: Double
    let saved: Double
    let unpricedCount: Int
    let categories: [WishCategoryStatistic]
    let currencyCode: String
    let availableCurrencyCodes: [String]
    let currencyItems: [WishItem]

    init(items: [WishItem], currencyCode: String? = nil) {
        activeItems = items.filter { !$0.isTrashed }
        let waiting = activeItems.filter { $0.status == .waiting }
        waitingItems = waiting
        availableCurrencyCodes = WishCurrency.orderedCodes(waiting.map(\.currencyCode))
        let selected = WishCurrency.resolvedSelection(preferred: currencyCode, availableCodes: availableCurrencyCodes)
        self.currencyCode = selected
        currencyItems = waiting.filter { $0.currencyCode == selected }
        let priced = currencyItems.filter { $0.savingsTarget != nil }
        budget = priced.reduce(0) { $0 + ($1.savingsTarget ?? 0) }
        saved = priced.reduce(0) { $0 + $1.savedAmountValue }
        unpricedCount = currencyItems.count - priced.count
        categories = Dictionary(grouping: waiting) {
            $0.category.trimmingCharacters(in: .whitespacesAndNewlines)
        }.map { name, items in
            WishCategoryStatistic(name: name, count: items.count)
        }.sorted { $0.count == $1.count ? $0.name < $1.name : $0.count > $1.count }
    }

    var completedCount: Int { items(for: .bought).count }
    var completionProgress: Double { activeItems.isEmpty ? 0 : Double(completedCount) / Double(activeItems.count) }

    var remaining: Double { max(budget - saved, 0) }
    var progress: Double { budget > 0 ? min(max(saved / budget, 0), 1) : 0 }

    func items(for status: WishItemStatus) -> [WishItem] {
        activeItems.filter { $0.status == status }
    }
}

struct WishCategoryStatistic: Identifiable {
    let name: String
    let count: Int

    var id: String { name }
}

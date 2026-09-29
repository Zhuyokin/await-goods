import Foundation
import SwiftData

enum CurrencyTests {
    @MainActor static func run() throws {
        let usd = WishItem(title: "Camera", price: 1000, savedAmount: 200)
        let cny = WishItem(title: "Bag", price: 6000, savedAmount: 1000, currencyCode: "CNY")
        let owned = WishItem(title: "Owned", price: 900, status: .bought, savedAmount: 900, currencyCode: "HKD")
        let stats = WishStatistics(items: [usd, cny, owned], currencyCode: "CNY")
        precondition(usd.currencyCode == "USD", "Existing/default wishes must use USD")
        precondition(stats.budget == 6000 && stats.saved == 1000 && stats.remaining == 5000)
        precondition(stats.activeItems.count == 3 && stats.completedCount == 1 && stats.waitingItems.count == 2)
        precondition(stats.currencyItems.count == 1 && Set(stats.availableCurrencyCodes) == ["USD", "CNY"])
        let fallback = WishStatistics(items: [cny], currencyCode: "USD")
        precondition(fallback.currencyCode == "CNY" && fallback.budget == 6000)

        let en = Locale(identifier: "en_US")
        precondition(WishCurrency.format(1234.5, code: "USD", locale: en) == "US$1,234.5")
        precondition(WishCurrency.format(1234, code: "CNY", locale: en) == "¥1,234")
        precondition(WishCurrency.format(1234, code: "HKD", locale: en) == "HK$1,234")
        precondition(WishCurrency.format(1234, code: "AUD", locale: en) == "A$1,234")
        precondition(WishCurrency.format(1234, code: "TWD", locale: en) == "NT$1,234")
        precondition(WishCurrency.format(1234.5, code: "JPY", locale: en) == "JP¥1,235")
        precondition(WishCurrency.parseAmount("1234.50", locale: en) == 1234.5)
        precondition(WishCurrency.parseAmount("1,234.50", locale: en) == 1234.5)
        precondition(WishCurrency.parseAmount("1234,50", locale: Locale(identifier: "de_DE")) == 1234.5)
        precondition(WishCurrency.parseAmount("1.234,50", locale: Locale(identifier: "de_DE")) == 1234.5)
        precondition(WishCurrency.parseAmount("12.50", locale: Locale(identifier: "de_DE")) == nil)
        for invalid in ["12abc", "1.2.3", "1,2", "12,34.50", "1.23,4", "NaN", "Infinity", ""] {
            precondition(WishCurrency.parseAmount(invalid, locale: en) == nil)
        }
        precondition(WishCurrency.inputText(1234.5, locale: Locale(identifier: "de_DE")) == "1234,5")
        for identifier in ["ar_EG", "fa_IR"] {
            let locale = Locale(identifier: identifier)
            let text = WishCurrency.inputText(1234.5, locale: locale)
            precondition(WishCurrency.parseAmount(text, locale: locale) == 1234.5)
        }
        precondition(WishCurrency.resolvedSelection(preferred: "HKD", availableCodes: ["CNY", "USD"]) == "USD")
        precondition(WishCurrency.resolvedSelection(preferred: "HKD", availableCodes: ["CNY", "AUD"]) == "CNY")

        let old = """
        {"id":"00000000-0000-0000-0000-000000000001","title":"Legacy","price":100,"sortIndex":0}
        """.data(using: .utf8)!
        let legacy = try JSONDecoder().decode(WishSnapshot.self, from: old)
        precondition(legacy.currencyCode == "USD")
        let restored = try JSONDecoder().decode(WishSnapshot.self, from: JSONEncoder().encode(cny.snapshot))
        precondition(restored.currencyCode == "CNY" && restored.price == 6000)
        let mixed = [usd.snapshot, cny.snapshot]
        precondition(WidgetContentFilter.select(mixed, group: nil, currencyCode: "CNY").map(\.id) == [cny.id])
        precondition(WidgetContentFilter.select(mixed, group: nil, itemID: usd.id, currencyCode: "CNY").isEmpty)
        precondition(WidgetContentFilter.select(mixed, group: nil, currencyCode: "AUD").isEmpty)
        let payload = WidgetSnapshotPayload(updatedAt: Date(), items: mixed, currencyCode: "CNY")
        let decodedPayload = try JSONDecoder().decode(WidgetSnapshotPayload.self, from: JSONEncoder().encode(payload))
        precondition(decodedPayload.currencyCode == "CNY")
        let ordered = WishSortIndexPolicy.sorted([cny, usd, WishItem(title: "Laptop", price: 2000)], by: .priceHigh)
        precondition(ordered.map(\.currencyCode) == ["CNY", "USD", "USD"])
        precondition(ordered[1].price == 2000 && ordered[2].price == 1000)
        try backupRoundTrip()
        print("Currency formatting, input, statistics, sorting and widget snapshot checks passed")
    }

    private static func backupRoundTrip() throws {
        let original = WishItem(title: "Bag", price: 6000, savedAmount: 1234.5, currencyCode: "CNY")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let data = try encoder.encode(WishItemExport(item: original))
        let export = try decoder.decode(WishItemExport.self, from: data)
        let restored = export.makeWishItem()
        precondition(restored.currencyCode == "CNY" && restored.price == 6000 && restored.savedAmountValue == 1234.5)
        let existing = WishItem(id: original.id, title: "Old copy", price: 10)
        export.apply(to: existing)
        precondition(existing.currencyCode == "CNY" && existing.savedAmountValue == 1234.5)
        var legacy = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        legacy.removeValue(forKey: "currencyCode")
        let old = try decoder.decode(WishItemExport.self, from: JSONSerialization.data(withJSONObject: legacy)).makeWishItem()
        precondition(old.currencyCode == "USD" && old.savedAmountValue == 1234.5)
        legacy.removeValue(forKey: "savedAmount")
        let oldest = try decoder.decode(WishItemExport.self, from: JSONSerialization.data(withJSONObject: legacy)).makeWishItem()
        precondition(oldest.currencyCode == "USD" && oldest.savedAmountValue == 0)
        print("JSON backup currency round-trip and legacy import checks passed")
    }

    @MainActor static func verifyMigration(at url: URL) throws {
        let container = try ModelContainer(for: WishItem.self, configurations: ModelConfiguration(url: url))
        let items = try container.mainContext.fetch(FetchDescriptor<WishItem>())
        precondition(items.count == 1)
        let old = items[0]
        precondition(old.id.uuidString == "B106A091-1D45-4998-A6A2-D7C55B2BFF61" && old.title == "Legacy camera")
        precondition(old.currencyCode == "USD", "An installed store must migrate missing currency to USD")
        precondition(old.price == 1234.5 && old.savedAmountValue == 234.25 && old.isPinned)
        precondition(old.photoData == Data([1, 2, 3]))
        old.currencyCode = "HKD"
        try container.mainContext.save()
        let reloaded = try ModelContext(container).fetch(FetchDescriptor<WishItem>())
        precondition(reloaded[0].currencyCode == "HKD" && reloaded[0].savedAmountValue == 234.25)
        print("Existing SwiftData store currency migration and persistence checks passed")
    }
}

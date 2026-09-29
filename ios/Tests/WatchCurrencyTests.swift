import Foundation

enum WatchCurrencyTests {
    static func run() throws {
        let legacy = """
        {"updatedAt":0,"items":[{"id":"00000000-0000-0000-0000-000000000001","title":"Camera","category":"数码","price":1000,"savedAmount":200,"priorityRawValue":2,"sortIndex":0,"statusRawValue":"waiting","updatedAt":0}]}
        """.data(using: .utf8)!
        let decodedLegacy = try JSONDecoder().decode(WatchWishPayload.self, from: legacy)
        precondition(decodedLegacy.currencyCode == "USD")
        precondition(decodedLegacy.items.first?.currencyCode == "USD")
        precondition(decodedLegacy.items.first?.savedAmount == 200)

        let item = WatchWishSnapshot(
            id: UUID(), title: "Bag", category: "出行", price: 6000,
            savedAmount: 1500, priorityRawValue: 2, sortIndex: 0,
            statusRawValue: "waiting", updatedAt: Date(timeIntervalSinceReferenceDate: 0),
            currencyCode: "CNY"
        )
        let payload = WatchWishPayload(
            updatedAt: Date(timeIntervalSinceReferenceDate: 0),
            items: [decodedLegacy.items[0], item], currencyCode: "CNY"
        )
        let restored = try JSONDecoder().decode(WatchWishPayload.self, from: JSONEncoder().encode(payload))
        precondition(restored.currencyCode == "CNY")
        precondition(restored.items.map(\.currencyCode) == ["USD", "CNY"])
        precondition(restored.items[1].price == 6000 && restored.items[1].savedAmount == 1500)
        print("Watch currency payload and legacy decoding checks passed")
    }
}

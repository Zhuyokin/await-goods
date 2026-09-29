import Foundation

enum WidgetCurrencyTests {
    static func run() {
        let usd = WishSnapshot(id: UUID(), title: "US camera", price: 500, savedAmount: 250,
                               sortIndex: 0, groups: ["Travel"], currencyCode: "USD")
        let aud = WishSnapshot(id: UUID(), title: "Australian bag", price: 100, savedAmount: 40,
                               sortIndex: 1, groups: ["Travel"], currencyCode: "AUD")
        let otherAUD = WishSnapshot(id: UUID(), title: "Australian watch", price: 200, savedAmount: 50,
                                    sortIndex: 2, groups: ["Daily"], currencyCode: "AUD")
        let items = [usd, aud, otherAUD]

        let jar = WishJarContent(items: items, selectedID: usd.id, currencyCode: "AUD")
        precondition(jar.displayItems.map(\.id) == [aud.id, otherAUD.id])
        precondition(jar.target == 300 && jar.saved == 90 && jar.count == 2,
                     "Jar totals must contain only the selected currency")
        precondition(jar.focus?.id == aud.id && jar.position == 1)
        precondition(jar.nextID(direction: 1) == otherAUD.id)
        precondition(jar.nextID(direction: -1) == otherAUD.id)

        let travel = WidgetContentFilter.select(items, group: "Travel", currencyCode: "AUD")
        precondition(travel.map(\.id) == [aud.id])
        let emptyGroup = WidgetContentFilter.select(items, group: "Daily", currencyCode: "USD")
        precondition(emptyGroup.isEmpty, "An empty currency/group combination must not fall back")
        let mismatchedProduct = WidgetContentFilter.select(items, group: nil, itemID: usd.id, currencyCode: "AUD")
        precondition(mismatchedProduct.isEmpty, "A configured product must not bypass the currency filter")

        let emptyJar = WishJarContent(items: items, currencyCode: "HKD")
        precondition(emptyJar.count == 0 && emptyJar.target == 0 && emptyJar.saved == 0)
        precondition(emptyJar.focus == nil && emptyJar.nextID(direction: 1) == nil)
        precondition(WishJarContent(items: items).displayItems.map(\.id) == [usd.id])
        print("Widget currency filtering, totals and navigation checks passed")
    }
}

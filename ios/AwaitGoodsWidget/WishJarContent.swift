import Foundation

struct WishJarContent {
    let displayItems: [WishSnapshot]
    let count: Int
    let saved: Double
    let target: Double
    let focus: WishSnapshot?
    let position: Int

    var progress: Double { target > 0 ? min(saved / target, 1) : 0 }

    func nextID(direction: Int) -> UUID? {
        WishBoardSelection.next(in: displayItems, currentID: focus?.id, direction: direction)
    }

    init(items: [WishSnapshot], selectedID: UUID? = nil) {
        displayItems = items
        count = items.count
        focus = WishBoardSelection.focus(in: items, selectedID: selectedID)
        position = focus.flatMap { selected in items.firstIndex { $0.id == selected.id } }.map { $0 + 1 } ?? 0
        var saved = 0.0
        var target = 0.0
        for item in items {
            guard let price = item.price, price.isFinite, price > 0 else { continue }
            target += price
            saved += item.savedAmount.isFinite ? min(max(item.savedAmount, 0), price) : 0
        }
        self.saved = saved
        self.target = target
    }
}

enum WishJarLayout {
    struct Pose {
        let x: CGFloat
        let y: CGFloat
        let width: CGFloat
        let angle: Double
    }

    static func pose(index: Int, count: Int) -> Pose {
        let anchors: [(CGFloat, CGFloat, Double)] = [(94, 141, -17), (153, 150, 15),
                                                     (79, 205, -18), (155, 208, 16)]
        let anchor = anchors[index % anchors.count]
        let layer = index / anchors.count
        let spread = CGFloat(layer == 0 ? 0 : (layer * 7) % 11 - 5)
        let width = max(46, 75 - log2(Double(max(count, 1)) + 1) * 2.5)
        return Pose(x: anchor.0 + spread, y: anchor.1 + spread * 0.6,
                    width: width + Double(index % 3) * 2,
                    angle: anchor.2 + Double(layer % 5 - 2) * 2)
    }
}

enum WishJarState {
    private static var defaults: UserDefaults {
        UserDefaults(suiteName: SharedAppGroup.identifier) ?? .standard
    }

    static func selection(scope: String) -> UUID? {
        defaults.string(forKey: "wishJar.selection.\(scope)").flatMap(UUID.init(uuidString:))
    }

    static func select(_ id: UUID, scope: String) {
        defaults.set(id.uuidString, forKey: "wishJar.selection.\(scope)")
    }
}

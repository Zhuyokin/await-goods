enum WishSortIndexPolicy {
    static func prepareForNewItem(existingItems: [WishItem]) -> Int {
        let orderedItems = existingItems.sorted {
            $0.sortIndex == $1.sortIndex ? $0.createdAt > $1.createdAt : $0.sortIndex < $1.sortIndex
        }
        guard let minimumIndex = orderedItems.first?.sortIndex else { return 0 }

        if minimumIndex == Int.min {
            for (offset, item) in orderedItems.enumerated() {
                item.sortIndex = offset + 1
            }
            return 0
        }

        return minimumIndex - 1
    }
}

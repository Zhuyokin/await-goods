import Foundation

enum WishSortIndexPolicy {
    static func sorted(_ items: [WishItem], by mode: WishSortMode, manualOrder: [UUID] = []) -> [WishItem] {
        let positions = Dictionary(uniqueKeysWithValues: manualOrder.enumerated().map { ($0.element, $0.offset) })
        return items.sorted { left, right in
            if left.isPinned != right.isPinned { return left.isPinned }
            switch mode {
            case .manual:
                let leftPosition = positions[left.id] ?? Int.max
                let rightPosition = positions[right.id] ?? Int.max
                if leftPosition != rightPosition { return leftPosition < rightPosition }
            case .recent:
                if left.createdAt != right.createdAt { return left.createdAt > right.createdAt }
            case .savings:
                if left.savingsProgress != right.savingsProgress { return left.savingsProgress > right.savingsProgress }
                if left.price != right.price { return (left.price ?? 0) > (right.price ?? 0) }
            case .priceHigh:
                if left.price != right.price { return (left.price ?? 0) > (right.price ?? 0) }
            case .priority:
                if left.priorityRawValue != right.priorityRawValue { return left.priorityRawValue > right.priorityRawValue }
            }
            if left.sortIndex != right.sortIndex { return left.sortIndex < right.sortIndex }
            if left.createdAt != right.createdAt { return left.createdAt > right.createdAt }
            return left.id.uuidString < right.id.uuidString
        }
    }

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

enum WishSortMode: String, CaseIterable, Identifiable {
    case manual, recent, savings, priceHigh, priority
    var id: String { rawValue }
    var title: String {
        switch self {
        case .manual: return "手动排序"
        case .recent: return "最近添加"
        case .savings: return "存钱进度"
        case .priceHigh: return "价格高低"
        case .priority: return "优先级"
        }
    }
}

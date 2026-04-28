import WidgetKit

enum WidgetSyncService {
    static func sync(items: [WishItem], limit: Int = 5) {
        let snapshots = items
            .filter { $0.status == .waiting }
            .sorted { lhs, rhs in
                if lhs.sortIndex == rhs.sortIndex {
                    return lhs.createdAt > rhs.createdAt
                }
                return lhs.sortIndex < rhs.sortIndex
            }
            .prefix(limit)
            .map(\.snapshot)

        WidgetSnapshotStore.save(items: Array(snapshots))
        WidgetCenter.shared.reloadAllTimelines()
    }
}

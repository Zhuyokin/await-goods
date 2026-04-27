import WidgetKit

enum WidgetSyncService {
    static func sync(items: [WishItem], limit: Int = 3) {
        let storedLimit = UserDefaults.standard.integer(forKey: "widgetItemLimit")
        let snapshotLimit = (1...3).contains(storedLimit) ? storedLimit : limit
        let snapshots = items
            .filter { $0.status == .waiting }
            .sorted { lhs, rhs in
                if lhs.sortIndex == rhs.sortIndex {
                    return lhs.createdAt > rhs.createdAt
                }
                return lhs.sortIndex < rhs.sortIndex
            }
            .prefix(snapshotLimit)
            .map(\.snapshot)

        WidgetSnapshotStore.save(items: Array(snapshots))
        WidgetCenter.shared.reloadAllTimelines()
    }
}

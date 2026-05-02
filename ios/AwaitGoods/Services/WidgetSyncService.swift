import Foundation
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

        let languageCode = UserDefaults.standard.string(forKey: "appLanguage") ?? AppLanguage.zhHans.rawValue
        WidgetSnapshotStore.save(items: Array(snapshots), languageCode: languageCode)
        WidgetCenter.shared.reloadAllTimelines()
    }
}

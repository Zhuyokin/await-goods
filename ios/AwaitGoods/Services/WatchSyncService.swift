import Foundation
import SwiftData
import WatchConnectivity

final class WatchSyncService: NSObject, WCSessionDelegate {
    static let shared = WatchSyncService()

    private weak var modelContainer: ModelContainer?

    private override init() {
        super.init()
    }

    func configure(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        activate()

        DispatchQueue.main.async { [weak self] in
            self?.syncFromStore()
        }
    }

    func sync(items: [WishItem]) {
        guard WCSession.isSupported() else { return }

        let payload = makePayload(items: items)
        guard let data = try? JSONEncoder().encode(payload) else { return }

        do {
            try WCSession.default.updateApplicationContext([
                WatchSyncMessageKey.payload: data
            ])
        } catch {
            return
        }
    }

    private func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    private func makePayload(items: [WishItem]) -> WatchWishPayload {
        let snapshots = items
            .filter { !$0.isTrashed }
            .sorted { lhs, rhs in
                if lhs.sortIndex == rhs.sortIndex {
                    return lhs.updatedAt > rhs.updatedAt
                }
                return lhs.sortIndex < rhs.sortIndex
            }
            .map { item in
                WatchWishSnapshot(
                    id: item.id,
                    title: item.title,
                    category: item.category,
                    price: item.price,
                    savedAmount: item.savedAmountValue,
                    priorityRawValue: item.priorityRawValue,
                    sortIndex: item.sortIndex,
                    statusRawValue: item.statusRawValue,
                    updatedAt: item.updatedAt
                )
            }

        return WatchWishPayload(updatedAt: Date(), items: snapshots)
    }

    @MainActor
    private func syncFromStore(replyHandler: (([String: Any]) -> Void)? = nil) {
        guard let modelContainer else {
            replyHandler?([:])
            return
        }

        let descriptor = FetchDescriptor<WishItem>()
        let items = (try? modelContainer.mainContext.fetch(descriptor)) ?? []
        let payload = makePayload(items: items)

        guard let data = try? JSONEncoder().encode(payload) else {
            replyHandler?([:])
            return
        }

        sync(items: items)
        replyHandler?([WatchSyncMessageKey.payload: data])
    }

    private func applyStatusChange(from message: [String: Any], replyHandler: (([String: Any]) -> Void)? = nil) {
        guard
            let itemIDString = message[WatchSyncMessageKey.itemID] as? String,
            let itemID = UUID(uuidString: itemIDString),
            let statusRawValue = message[WatchSyncMessageKey.status] as? String,
            let status = WishItemStatus(rawValue: statusRawValue),
            let modelContainer
        else {
            replyHandler?([:])
            return
        }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            let context = modelContainer.mainContext
            let descriptor = FetchDescriptor<WishItem>()
            let items = (try? context.fetch(descriptor)) ?? []

            if let item = items.first(where: { $0.id == itemID && !$0.isTrashed }) {
                item.status = status
                try? context.save()

                if status == .waiting {
                    Task { await NotificationScheduler.schedule(for: item) }
                } else {
                    NotificationScheduler.cancel(for: item)
                }

                WidgetSyncService.sync(items: items)
            }

            let payload = self.makePayload(items: items)
            let data = try? JSONEncoder().encode(payload)
            replyHandler?(data.map { [WatchSyncMessageKey.payload: $0] } ?? [:])
        }
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        guard activationState == .activated else { return }
        DispatchQueue.main.async { [weak self] in
            self?.syncFromStore()
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    func sessionWatchStateDidChange(_ session: WCSession) {
        guard session.activationState == .activated else { return }
        DispatchQueue.main.async { [weak self] in
            self?.syncFromStore()
        }
    }

    func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        switch message[WatchSyncMessageKey.kind] as? String {
        case WatchSyncMessageKey.requestSync:
            DispatchQueue.main.async { [weak self] in
                self?.syncFromStore(replyHandler: replyHandler)
            }
        case WatchSyncMessageKey.updateStatus:
            applyStatusChange(from: message, replyHandler: replyHandler)
        default:
            replyHandler([:])
        }
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        guard userInfo[WatchSyncMessageKey.kind] as? String == WatchSyncMessageKey.updateStatus else { return }
        applyStatusChange(from: userInfo)
    }
}

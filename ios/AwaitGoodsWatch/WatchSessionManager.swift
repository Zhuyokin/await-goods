import Foundation
import WatchConnectivity

final class WatchSessionManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchSessionManager()

    @Published private(set) var items: [WatchWishSnapshot] = []
    @Published private(set) var lastUpdatedAt: Date?
    @Published private(set) var isReachable = false

    #if DEBUG
    private static let cachedPayloadKey = "awaitGoods.watch.cachedPayload.debug"
    #else
    private static let cachedPayloadKey = "awaitGoods.watch.cachedPayload"
    #endif
    private var pendingMessages: [[String: Any]] = []

    private override init() {
        super.init()
        restoreCachedPayload()
    }

    func start() {
        guard WCSession.isSupported() else { return }

        let session = WCSession.default
        session.delegate = self
        session.activate()

        if !session.receivedApplicationContext.isEmpty {
            apply(context: session.receivedApplicationContext)
        }
    }

    func requestSync() {
        guard WCSession.isSupported() else { return }

        let session = WCSession.default
        guard session.activationState == .activated else {
            start()
            return
        }

        guard session.isReachable else { return }
        session.sendMessage(
            [WatchSyncMessageKey.kind: WatchSyncMessageKey.requestSync],
            replyHandler: { [weak self] reply in
                self?.apply(context: reply)
            },
            errorHandler: nil
        )
    }

    func updateStatus(_ status: WatchWishStatus, for itemID: UUID) {
        if let index = items.firstIndex(where: { $0.id == itemID }) {
            items[index].status = status
            cacheCurrentItems()
        }

        let message: [String: Any] = [
            WatchSyncMessageKey.kind: WatchSyncMessageKey.updateStatus,
            WatchSyncMessageKey.itemID: itemID.uuidString,
            WatchSyncMessageKey.status: status.rawValue
        ]
        sendOrQueue(message)
    }

    private func sendOrQueue(_ message: [String: Any]) {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default

        guard session.activationState == .activated else {
            pendingMessages.append(message)
            start()
            return
        }

        if session.isReachable {
            session.sendMessage(
                message,
                replyHandler: { [weak self] reply in
                    self?.apply(context: reply)
                },
                errorHandler: { [weak self] _ in
                    DispatchQueue.main.async {
                        self?.transfer(message)
                    }
                }
            )
        } else {
            transfer(message)
        }
    }

    private func transfer(_ message: [String: Any]) {
        guard WCSession.isSupported(), WCSession.default.activationState == .activated else {
            pendingMessages.append(message)
            return
        }
        WCSession.default.transferUserInfo(message)
    }

    private func flushPendingMessages() {
        let messages = pendingMessages
        pendingMessages.removeAll()
        messages.forEach(sendOrQueue)
    }

    private func apply(context: [String: Any]) {
        guard let data = context[WatchSyncMessageKey.payload] as? Data else { return }
        apply(payloadData: data)
    }

    private func apply(payloadData: Data) {
        guard let payload = try? JSONDecoder().decode(WatchWishPayload.self, from: payloadData) else { return }

        DispatchQueue.main.async { [weak self] in
            self?.items = payload.items
            self?.lastUpdatedAt = payload.updatedAt
            UserDefaults.standard.set(payloadData, forKey: Self.cachedPayloadKey)
        }
    }

    private func restoreCachedPayload() {
        guard
            let data = UserDefaults.standard.data(forKey: Self.cachedPayloadKey),
            let payload = try? JSONDecoder().decode(WatchWishPayload.self, from: data)
        else {
            #if DEBUG
            items = Self.debugItems
            #endif
            return
        }

        items = payload.items
        lastUpdatedAt = payload.updatedAt
    }

    private func cacheCurrentItems() {
        let payload = WatchWishPayload(updatedAt: Date(), items: items)
        guard let data = try? JSONEncoder().encode(payload) else { return }
        lastUpdatedAt = payload.updatedAt
        UserDefaults.standard.set(data, forKey: Self.cachedPayloadKey)
    }

    #if DEBUG
    private static let debugItems: [WatchWishSnapshot] = [
        WatchWishSnapshot(
            id: UUID(uuidString: "01A4F438-7A6B-44B4-8A9C-2A4C3EF5E8A1")!,
            title: "Apple Watch 表带",
            category: "数码",
            price: 379,
            savedAmount: 120,
            priorityRawValue: 3,
            sortIndex: 0,
            statusRawValue: WatchWishStatus.waiting.rawValue,
            updatedAt: Date().addingTimeInterval(-600)
        ),
        WatchWishSnapshot(
            id: UUID(uuidString: "17DBD6CB-65DF-4F6F-8B18-6F594A93A4B2")!,
            title: "降噪耳机",
            category: "数码",
            price: 1_899,
            savedAmount: 950,
            priorityRawValue: 3,
            sortIndex: 1,
            statusRawValue: WatchWishStatus.waiting.rawValue,
            updatedAt: Date().addingTimeInterval(-3_600)
        ),
        WatchWishSnapshot(
            id: UUID(uuidString: "2ED4B37F-292A-4D21-9EBC-FA6204C39AC3")!,
            title: "周末徒步鞋",
            category: "运动",
            price: 899,
            savedAmount: 200,
            priorityRawValue: 2,
            sortIndex: 2,
            statusRawValue: WatchWishStatus.waiting.rawValue,
            updatedAt: Date().addingTimeInterval(-7_200)
        ),
        WatchWishSnapshot(
            id: UUID(uuidString: "3C984207-F1C0-41CF-BF95-4B6979C072D4")!,
            title: "设计类纸质书",
            category: "书影音",
            price: 168,
            savedAmount: 168,
            priorityRawValue: 1,
            sortIndex: 3,
            statusRawValue: WatchWishStatus.bought.rawValue,
            updatedAt: Date().addingTimeInterval(-86_400)
        ),
        WatchWishSnapshot(
            id: UUID(uuidString: "4F71555A-A2DE-43B7-944E-46C90D5D10E5")!,
            title: "复古台灯",
            category: "家居",
            price: 529,
            savedAmount: 80,
            priorityRawValue: 1,
            sortIndex: 4,
            statusRawValue: WatchWishStatus.released.rawValue,
            updatedAt: Date().addingTimeInterval(-172_800)
        )
    ]
    #endif

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        DispatchQueue.main.async { [weak self] in
            self?.isReachable = session.isReachable
            guard activationState == .activated else { return }
            self?.apply(context: session.receivedApplicationContext)
            self?.flushPendingMessages()
            self?.requestSync()
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async { [weak self] in
            self?.isReachable = session.isReachable
            if session.isReachable {
                self?.requestSync()
            }
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        apply(context: applicationContext)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        apply(context: userInfo)
    }

    func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        apply(context: message)
        replyHandler([:])
    }
}

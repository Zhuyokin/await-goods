import Foundation
import UserNotifications

extension Notification.Name {
    static let openAwaitGoodsWishList = Notification.Name("openAwaitGoodsWishList")
}

enum NotificationScheduler {
    private static let center = UNUserNotificationCenter.current()
    private static let maximumPendingWishReminders = 64

    static func configure() {
        center.delegate = WishNotificationDelegate.shared
    }

    static func requestAuthorizationIfNeeded() async -> Bool {
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            do {
                return try await center.requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                return false
            }
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    @discardableResult
    static func schedule(for item: WishItem) async -> Bool {
        cancel(for: item)

        guard item.notifyEnabled,
              item.status == .waiting,
              !item.isTrashed,
              let date = nextNotificationDate(for: item),
              date > Date()
        else { return false }

        guard await requestAuthorizationIfNeeded() else { return false }
        return await addScheduledRequest(for: item, at: date)
    }

    static func synchronize(items: [WishItem]) async {
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized ||
                settings.authorizationStatus == .provisional ||
                settings.authorizationStatus == .ephemeral
        else { return }

        let pendingRequests = await center.pendingNotificationRequests()
        let wishRequestIDs = pendingRequests
            .map(\.identifier)
            .filter { $0.hasPrefix("wish-item-") }
        center.removePendingNotificationRequests(withIdentifiers: wishRequestIDs)

        let scheduledItems = items
            .compactMap { item -> (WishItem, Date)? in
                guard item.notifyEnabled,
                      item.status == .waiting,
                      !item.isTrashed,
                      let date = nextNotificationDate(for: item),
                      date > Date()
                else { return nil }
                return (item, date)
            }
            .sorted { $0.1 < $1.1 }
            .prefix(maximumPendingWishReminders)

        for (item, date) in scheduledItems {
            _ = await addScheduledRequest(for: item, at: date)
        }
    }

    static func cancel(for item: WishItem) {
        let requestID = identifier(for: item)
        center.removePendingNotificationRequests(withIdentifiers: [requestID])
        center.removeDeliveredNotifications(withIdentifiers: [requestID])
    }

    static func cancelAllWishNotifications() {
        center.getPendingNotificationRequests { requests in
            let identifiers = requests
                .map(\.identifier)
                .filter { $0.hasPrefix("wish-item-") }
            center.removePendingNotificationRequests(withIdentifiers: identifiers)
            center.removeDeliveredNotifications(withIdentifiers: identifiers)
        }
    }

    private static func addScheduledRequest(for item: WishItem, at date: Date) async -> Bool {
        let content = notificationContent(for: item)
        let interval = max(date.timeIntervalSinceNow, 1)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(
            identifier: identifier(for: item),
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
            return true
        } catch {
            return false
        }
    }

    private static func notificationContent(for item: WishItem) -> UNMutableNotificationContent {
        let language = currentAppLanguage
        let message = WishReminderMessageBuilder.make(
            title: item.title,
            priority: item.priority,
            category: item.category,
            savedAmount: item.savedAmountValue,
            targetAmount: item.savingsTarget,
            language: language
        )
        let content = UNMutableNotificationContent()
        content.title = message.title
        content.body = message.body
        content.sound = .default
        content.userInfo = [
            "destination": "wishList",
            "wishItemID": item.id.uuidString
        ]
        return content
    }

    private static var currentAppLanguage: AppLanguage {
        let rawValue = UserDefaults.standard.string(forKey: "appLanguage") ?? AppLanguage.zhHans.rawValue
        return AppLanguage(rawValue: rawValue) ?? .zhHans
    }

    private static func identifier(for item: WishItem) -> String {
        "wish-item-\(item.id.uuidString)"
    }

    private static func nextNotificationDate(for item: WishItem) -> Date? {
        [item.targetDate, item.waitUntil]
            .compactMap { $0 }
            .filter { $0 > Date() }
            .sorted()
            .first
    }

}

private final class WishNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = WishNotificationDelegate()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .openAwaitGoodsWishList, object: nil)
        }
        completionHandler()
    }
}

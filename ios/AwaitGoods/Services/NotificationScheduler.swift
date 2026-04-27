import Foundation
import UserNotifications

enum NotificationScheduler {
    static func requestAuthorizationIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
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

    static func schedule(for item: WishItem) async {
        await cancel(for: item)

        guard item.notifyEnabled, item.status == .waiting else { return }
        guard await requestAuthorizationIfNeeded() else { return }
        guard let date = nextNotificationDate(for: item) else { return }

        let content = UNMutableNotificationContent()
        content.title = "候物"
        content.body = "你等的「\(item.title)」可以再看看了。"
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier(for: item), content: content, trigger: trigger)

        try? await UNUserNotificationCenter.current().add(request)
    }

    static func cancel(for item: WishItem) async {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier(for: item)])
    }

    static func cancelAllWishNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let identifiers = requests
                .map(\.identifier)
                .filter { $0.hasPrefix("wish-item-") }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        }
    }

    private static func identifier(for item: WishItem) -> String {
        "wish-item-\(item.id.uuidString)"
    }

    private static func nextNotificationDate(for item: WishItem) -> Date? {
        let now = Date()
        let candidates = [item.waitUntil, item.targetDate]
            .compactMap { $0 }
            .map { normalizeNotificationDate($0) }
            .filter { $0 > now }

        return candidates.sorted().first
    }

    private static func normalizeNotificationDate(_ date: Date) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        components.hour = 9
        components.minute = 0
        return Calendar.current.date(from: components) ?? date
    }
}

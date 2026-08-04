import Foundation
import UserNotifications

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
        let content = UNMutableNotificationContent()
        content.title = notificationTitle(for: item, language: language)
        content.body = notificationBody(for: item, language: language)
        content.sound = .default
        content.userInfo = ["wishItemID": item.id.uuidString]
        return content
    }

    private static func notificationTitle(for item: WishItem, language: AppLanguage) -> String {
        if item.priority == .high {
            return String(format: language.text("高优先级候物：%@"), item.title)
        }

        if item.savingsProgress >= 0.8, !item.isSavingsComplete {
            return String(format: language.text("快存到了：%@"), item.title)
        }

        return String(format: language.text("「%@」还在你的候物清单里"), item.title)
    }

    private static func notificationBody(for item: WishItem, language: AppLanguage) -> String {
        let priorityText = String(format: language.text("%@优先级"), language.text(item.priority.title))
        let metadata = [priorityText, item.category.trimmingCharacters(in: .whitespacesAndNewlines)]
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
        let usesCJKPunctuation = language == .zhHans || language == .zhHant || language == .ja
        let sentenceEnd = usesCJKPunctuation ? "。" : "."
        let sentenceSpacing = usesCJKPunctuation ? "" : " "

        if let price = item.savingsTarget {
            let progressText = String(
                format: language.text("已存 %@ / %@（%d%%），还差 %@。"),
                moneyText(item.savedAmountValue),
                moneyText(price),
                Int((item.savingsProgress * 100).rounded()),
                moneyText(item.remainingSavingsAmount ?? 0)
            )
            return "\(progressText)\(sentenceSpacing)\(metadata)\(sentenceEnd)\(sentenceSpacing)\(language.text("再看一眼，它现在仍值得买吗？"))"
        }

        return "\(metadata)\(sentenceEnd)\(sentenceSpacing)\(language.text("回来看一眼，确认它是否仍值得留在清单里。"))"
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

    private static func moneyText(_ value: Double) -> String {
        "$\(value.formatted(.number.precision(.fractionLength(0...2))))"
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
}

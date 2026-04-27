import Foundation
import SwiftData

@Model
final class WishItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var price: Double?
    var linkString: String
    var note: String
    var category: String
    var priorityRawValue: Int
    var statusRawValue: String
    var markColorRawValue: String
    var sortIndex: Int
    var createdAt: Date
    var updatedAt: Date
    var waitUntil: Date?
    var targetDate: Date?
    var notifyEnabled: Bool

    init(
        id: UUID = UUID(),
        title: String,
        price: Double? = nil,
        linkString: String = "",
        note: String = "",
        category: String = "",
        priority: WishPriority = .medium,
        status: WishItemStatus = .waiting,
        markColor: MarkColor = .none,
        sortIndex: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        waitUntil: Date? = nil,
        targetDate: Date? = nil,
        notifyEnabled: Bool = true
    ) {
        self.id = id
        self.title = title
        self.price = price
        self.linkString = linkString
        self.note = note
        self.category = category
        self.priorityRawValue = priority.rawValue
        self.statusRawValue = status.rawValue
        self.markColorRawValue = markColor.rawValue
        self.sortIndex = sortIndex
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.waitUntil = waitUntil
        self.targetDate = targetDate
        self.notifyEnabled = notifyEnabled
    }

    var status: WishItemStatus {
        get { WishItemStatus(rawValue: statusRawValue) ?? .waiting }
        set {
            statusRawValue = newValue.rawValue
            updatedAt = Date()
        }
    }

    var priority: WishPriority {
        get { WishPriority(rawValue: priorityRawValue) ?? .medium }
        set {
            priorityRawValue = newValue.rawValue
            updatedAt = Date()
        }
    }

    var markColor: MarkColor {
        get { MarkColor(rawValue: markColorRawValue) ?? .none }
        set {
            markColorRawValue = newValue.rawValue
            updatedAt = Date()
        }
    }

    var linkURL: URL? {
        let trimmed = linkString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return URL(string: trimmed)
    }

    var snapshot: WishSnapshot {
        WishSnapshot(id: id, title: title, price: price, waitUntil: waitUntil, sortIndex: sortIndex)
    }
}
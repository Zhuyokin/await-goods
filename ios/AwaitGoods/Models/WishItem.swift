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
    var savedAmount: Double?
    var trashedAt: Date?

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
        notifyEnabled: Bool = false,
        savedAmount: Double? = nil,
        trashedAt: Date? = nil
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
        self.savedAmount = savedAmount
        self.trashedAt = trashedAt
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

    var isTrashed: Bool {
        trashedAt != nil
    }

    func moveToTrash(at date: Date = Date()) {
        trashedAt = date
        notifyEnabled = false
        updatedAt = date
    }

    func restoreFromTrash(at date: Date = Date()) {
        trashedAt = nil
        updatedAt = date
    }

    var linkURL: URL? {
        let trimmed = linkString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return URL(string: trimmed)
    }

    var savedAmountValue: Double {
        get {
            let amount = max(savedAmount ?? 0, 0)
            guard let savingsTarget else { return amount }
            return min(amount, savingsTarget)
        }
        set {
            let amount = max(newValue, 0)
            if let savingsTarget {
                savedAmount = min(amount, savingsTarget)
            } else {
                savedAmount = amount
            }
            updatedAt = Date()
        }
    }

    var savingsTarget: Double? {
        guard let price, price > 0 else { return nil }
        return price
    }

    var savingsProgress: Double {
        guard let savingsTarget else { return 0 }
        return min(savedAmountValue / savingsTarget, 1)
    }

    var remainingSavingsAmount: Double? {
        guard let savingsTarget else { return nil }
        return max(savingsTarget - savedAmountValue, 0)
    }

    var isSavingsComplete: Bool {
        guard let savingsTarget else { return false }
        return savedAmountValue >= savingsTarget
    }

    func reconcileSavingsStatus() {
        if isSavingsComplete {
            status = .bought
        }
    }

    var snapshot: WishSnapshot {
        WishSnapshot(id: id, title: title, price: price, savedAmount: savedAmountValue, sortIndex: sortIndex)
    }
}

enum WishCategoryCatalog {
    static let defaultCategories = ["数码", "衣物", "家居", "书影音", "礼物", "运动"]

    static func suggestions(from items: [WishItem], including draftCategory: String = "") -> [String] {
        var seenCategories = Set<String>()
        var suggestions: [String] = []

        for category in defaultCategories + items.map(\.category) + [draftCategory] {
            let trimmedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedCategory.isEmpty else { continue }

            let categoryKey = trimmedCategory.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            guard seenCategories.insert(categoryKey).inserted else { continue }
            suggestions.append(trimmedCategory)
        }

        return suggestions
    }
}
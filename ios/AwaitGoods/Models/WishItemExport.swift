import Foundation

struct WishItemExport: Codable {
    let id: UUID
    let title: String
    let price: Double?
    let currencyCode: String?
    let link: String
    let note: String
    let category: String
    let priority: String
    let status: String
    let markColor: String
    let savedAmount: Double
    let photoData: Data?
    let reminderDate: Date?
    let notifyEnabled: Bool?
    let sortIndex: Int
    let isPinned: Bool?
    let createdAt: Date
    let updatedAt: Date

    init(item: WishItem) {
        id = item.id
        title = item.title
        price = item.price
        currencyCode = item.currencyCode
        link = item.linkString
        note = item.note
        category = item.category
        priority = String(item.priority.rawValue)
        status = item.status.rawValue
        markColor = item.markColor.rawValue
        photoData = item.photoData
        savedAmount = item.savedAmountValue
        reminderDate = item.targetDate ?? item.waitUntil
        notifyEnabled = item.notifyEnabled
        sortIndex = item.sortIndex
        isPinned = item.isPinned
        createdAt = item.createdAt
        updatedAt = item.updatedAt
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, price, currencyCode, link, note, category, priority, status, markColor
        case savedAmount, photoData, reminderDate, notifyEnabled, sortIndex, isPinned, createdAt, updatedAt
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(UUID.self, forKey: .id)
        title = try values.decode(String.self, forKey: .title)
        price = try values.decodeIfPresent(Double.self, forKey: .price)
        currencyCode = try values.decodeIfPresent(String.self, forKey: .currencyCode)
        link = try values.decode(String.self, forKey: .link)
        note = try values.decode(String.self, forKey: .note)
        category = try values.decode(String.self, forKey: .category)
        priority = try values.decode(String.self, forKey: .priority)
        status = try values.decode(String.self, forKey: .status)
        markColor = try values.decode(String.self, forKey: .markColor)
        savedAmount = try values.decodeIfPresent(Double.self, forKey: .savedAmount) ?? 0
        photoData = try values.decodeIfPresent(Data.self, forKey: .photoData)
        reminderDate = try values.decodeIfPresent(Date.self, forKey: .reminderDate)
        notifyEnabled = try values.decodeIfPresent(Bool.self, forKey: .notifyEnabled)
        sortIndex = try values.decode(Int.self, forKey: .sortIndex)
        isPinned = try values.decodeIfPresent(Bool.self, forKey: .isPinned)
        createdAt = try values.decode(Date.self, forKey: .createdAt)
        updatedAt = try values.decode(Date.self, forKey: .updatedAt)
    }

    func makeWishItem() -> WishItem {
        WishItem(
            id: id,
            title: trimmedTitle,
            price: normalizedPrice,
            linkString: link.trimmingCharacters(in: .whitespacesAndNewlines),
            note: note,
            category: category.trimmingCharacters(in: .whitespacesAndNewlines),
            priority: WishPriority.fromBackupValue(priority),
            status: WishItemStatus.fromBackupValue(status),
            markColor: MarkColor.fromBackupValue(markColor),
            sortIndex: sortIndex,
            isPinned: isPinned ?? false,
            createdAt: createdAt,
            updatedAt: updatedAt,
            targetDate: reminderDate,
            notifyEnabled: notifyEnabled == true && reminderDate != nil && WishItemStatus.fromBackupValue(status) == .waiting,
            savedAmount: normalizedSavedAmount,
            photoData: photoData,
            currencyCode: resolvedCurrencyCode
        )
    }

    func apply(to item: WishItem) {
        item.title = trimmedTitle
        item.price = normalizedPrice
        item.currencyCode = resolvedCurrencyCode
        item.linkString = link.trimmingCharacters(in: .whitespacesAndNewlines)
        item.note = note
        item.category = category.trimmingCharacters(in: .whitespacesAndNewlines)
        item.priority = WishPriority.fromBackupValue(priority)
        item.status = WishItemStatus.fromBackupValue(status)
        item.markColor = MarkColor.fromBackupValue(markColor)
        item.photoData = photoData
        item.savedAmountValue = normalizedSavedAmount
        item.waitUntil = nil
        item.targetDate = reminderDate
        item.notifyEnabled = notifyEnabled == true && reminderDate != nil && item.status == .waiting
        item.sortIndex = sortIndex
        item.isPinned = isPinned ?? false
        item.createdAt = createdAt
        item.updatedAt = updatedAt
        item.trashedAt = nil
    }

    var resolvedCurrencyCode: String {
        currencyCode?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() ?? "USD"
    }

    private var trimmedTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? title : trimmed
    }

    private var normalizedPrice: Double? {
        guard let price, price > 0 else { return nil }
        return price
    }

    private var normalizedSavedAmount: Double {
        max(savedAmount, 0)
    }
}


private extension WishPriority {
    static func fromBackupValue(_ value: String) -> WishPriority {
        switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "1", "low", "低":
            return .low
        case "3", "high", "高":
            return .high
        default:
            return .medium
        }
    }
}

private extension WishItemStatus {
    static func fromBackupValue(_ value: String) -> WishItemStatus {
        switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "waiting", "想买", "想買":
            return .waiting
        case "bought", "已拥有", "已擁有":
            return .bought
        case "released", "放下":
            return .released
        default:
            return .waiting
        }
    }
}

private extension MarkColor {
    static func fromBackupValue(_ value: String) -> MarkColor {
        switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "green", "绿色", "綠色":
            return .green
        case "yellow", "黄色", "黃色":
            return .yellow
        case "pink", "粉色":
            return .pink
        case "gray", "grey", "灰色":
            return .gray
        default:
            return .none
        }
    }
}

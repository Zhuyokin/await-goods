import Foundation

enum WishDeepLink: Equatable {
    case home, add, wish(UUID)

    init?(url: URL) {
        guard url.scheme?.lowercased() == "awaitgoods" else { return nil }
        switch url.host?.lowercased() {
        case "home": self = .home
        case "add": self = .add
        case "wish":
            guard let id = UUID(uuidString: String(url.path.dropFirst())) else { return nil }
            self = .wish(id)
        default: return nil
        }
    }

    var url: URL {
        switch self {
        case .home: return URL(string: "awaitgoods://home")!
        case .add: return URL(string: "awaitgoods://add")!
        case .wish(let id): return URL(string: "awaitgoods://wish/\(id.uuidString)")!
        }
    }
}

enum WishBoardSelection {
    static func focus(in items: [WishSnapshot], selectedID: UUID?) -> WishSnapshot? {
        items.first { $0.id == selectedID } ?? items.first
    }

    static func next(in items: [WishSnapshot], currentID: UUID?, direction: Int) -> UUID? {
        guard !items.isEmpty else { return nil }
        let index = items.firstIndex { $0.id == currentID } ?? 0
        let offset = direction < 0 ? items.count - 1 : 1
        return items[(index + offset) % items.count].id
    }
}

struct WidgetSavingsReceipt: Codable {
    let id: UUID
    let itemID: UUID
    let title: String
    let previousSavedAmount: Double?
    let previousStatus: String
    let savedAmount: Double
    let status: String
    let updatedAt: Date
    let amount: Double
}

struct WishBoardFeedback: Codable {
    enum Outcome: String, Codable { case saved, undone, stale, failed }
    let outcome: Outcome
    let receipt: WidgetSavingsReceipt?
    var date = Date()

    func isVisible(at date: Date) -> Bool {
        date.timeIntervalSince(self.date) < 300
    }
}

enum WishBoardState {
    private static var defaults: UserDefaults {
        UserDefaults(suiteName: SharedAppGroup.identifier) ?? .standard
    }

    static func selection(scope: String) -> UUID? {
        defaults.string(forKey: "wishBoard.selection.\(scope)").flatMap(UUID.init(uuidString:))
    }

    static func select(_ id: UUID?, scope: String) {
        defaults.set(id?.uuidString, forKey: "wishBoard.selection.\(scope)")
    }

    static func feedback(scope: String) -> WishBoardFeedback? {
        guard let data = defaults.data(forKey: "wishBoard.feedback.\(scope)") else { return nil }
        return try? JSONDecoder().decode(WishBoardFeedback.self, from: data)
    }

    static func saveFeedback(_ feedback: WishBoardFeedback, scope: String) {
        guard let data = try? JSONEncoder().encode(feedback) else { return }
        defaults.set(data, forKey: "wishBoard.feedback.\(scope)")
    }
}

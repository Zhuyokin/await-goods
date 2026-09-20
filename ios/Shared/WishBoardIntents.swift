import AppIntents
import Foundation

struct RecordWishSavingsIntent: AppIntent {
    static var title: LocalizedStringResource = "记录心愿储蓄"
    static var openAppWhenRun = false
    static var isDiscoverable = false

    @Parameter(title: "心愿 ID") var itemID: String
    @Parameter(title: "储蓄金额") var amount: Double
    @Parameter(title: "数据版本") var revision: Double
    @Parameter(title: "内容分组") var scope: String

    init() { }
    init(item: WishSnapshot, amount: Double, scope: String) {
        itemID = item.id.uuidString
        self.amount = amount
        revision = item.updatedAt?.timeIntervalSince1970 ?? 0
        self.scope = scope
    }

    func perform() async throws -> some IntentResult {
        try await record()
        return .result()
    }

    private func record() async throws {
        #if AWAITGOODS_APP
        await WidgetActionService.deposit(itemID: itemID, amount: amount, revision: revision, scope: scope)
        #else
        // The app-only conformance routes database writes to the owning app process.
        throw CocoaError(.featureUnsupported)
        #endif
    }
}

struct UndoWishSavingsIntent: AppIntent {
    static var title: LocalizedStringResource = "撤销储蓄记录"
    static var openAppWhenRun = false
    static var isDiscoverable = false
    @Parameter(title: "记录 ID") var receiptID: String
    @Parameter(title: "内容分组") var scope: String

    init() { }
    init(receiptID: UUID, scope: String) {
        self.receiptID = receiptID.uuidString
        self.scope = scope
    }

    func perform() async throws -> some IntentResult {
        try await undo()
        return .result()
    }

    private func undo() async throws {
        #if AWAITGOODS_APP
        await WidgetActionService.undo(receiptID: receiptID, scope: scope)
        #else
        throw CocoaError(.featureUnsupported)
        #endif
    }
}

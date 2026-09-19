import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.appLanguage) private var appLanguage
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("appearanceMode") private var appearanceMode = AppAppearanceMode.system.rawValue
    @AppStorage("appLanguage") private var appLanguageRawValue = AppLanguage.zhHans.rawValue
    @AppStorage(AppTheme.storageKey) private var appThemeRawValue = AppTheme.springPaper.rawValue

    let items: [WishItem]
    let onChange: () -> Void

    @State private var exportURL: URL?
    @State private var showingImporter = false
    @State private var showingClearConfirmation = false
    @State private var dataTransferMessage: DataTransferMessage?
    private let supportEmail = "yokinzhu@gmail.com"

    var showsDoneButton = false
    private var activeItems: [WishItem] { items.filter { !$0.isTrashed } }
    private var currentLanguage: AppLanguage { AppLanguage(rawValue: appLanguageRawValue) ?? .zhHans }
    private var currentAppearanceMode: AppAppearanceMode { AppAppearanceMode(rawValue: appearanceMode) ?? .system }
    private var currentTheme: AppTheme { AppTheme(rawValue: appThemeRawValue) ?? .springPaper }
    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.11"
    }

    var body: some View {
        NavigationStack {
            List {
                preferencesSection
                backupSection
                aboutSection
                clearDataSection
            }
            .settingsListStyle()
            .navigationTitle(appLanguage.text("设置"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if showsDoneButton {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(appLanguage.text("完成")) { dismiss() }
                            .fontWeight(.medium)
                    }
                }
            }
            .alert(appLanguage.text("所有候物都会被删除"), isPresented: $showingClearConfirmation) {
                Button(appLanguage.text("取消"), role: .cancel) { }
                Button(appLanguage.text("清空"), role: .destructive) { clearAll() }
            }
            .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.json], allowsMultipleSelection: false, onCompletion: handleImportSelection)
            .alert(item: $dataTransferMessage) { message in
                Alert(
                    title: Text(message.title),
                    message: Text(message.message),
                    dismissButton: .default(Text(appLanguage.text("完成")))
                )
            }
        }
    }

    private var preferencesSection: some View {
        Section {
            NavigationLink {
                languageSelectionPage
            } label: {
                settingsRow("语言", icon: "globe.asia.australia", value: currentLanguage.title)
            }

            NavigationLink {
                appearanceSelectionPage
            } label: {
                settingsRow("外观模式", icon: "circle.lefthalf.filled", value: appLanguage.text(currentAppearanceMode.title))
            }

            NavigationLink {
                themeSelectionPage
            } label: {
                settingsRow("主题配色", icon: "paintpalette", value: appLanguage.text(currentTheme.title))
            }
        } header: {
            Text(appLanguage.text("外观与语言"))
        }
        .listRowBackground(HWTheme.cardBackground)
    }

    private var backupSection: some View {
        Section {
            Button {
                showingImporter = true
            } label: {
                settingsRow("导入备份文件", icon: "square.and.arrow.down")
            }

            Button {
                exportURL = makeExportFile()
            } label: {
                settingsRow("生成导出文件", icon: "square.and.arrow.up")
            }

            if let exportURL {
                ShareLink(item: exportURL) {
                    settingsRow("分享导出文件", icon: "paperplane", value: appLanguage.text("文件已生成"))
                }
            }
        } header: {
            Text(appLanguage.text("数据与安全"))
        } footer: {
            Text(appLanguage.text("通过 JSON 文件备份、恢复或合并候物"))
        }
        .listRowBackground(HWTheme.cardBackground)
    }

    private var aboutSection: some View {
        Section(appLanguage.text("关于 App")) {
            if let supportEmailURL = URL(string: "mailto:\(supportEmail)") {
                Link(destination: supportEmailURL) {
                    externalLinkRow("联系客服", icon: "envelope")
                }
            }

            Link(destination: AppStoreLinks.reviewURL) {
                externalLinkRow("去评分", icon: "star")
            }

            Link(destination: AppStoreLinks.developerPageURL) {
                externalLinkRow("更多我的应用", icon: "square.grid.2x2")
            }
        }
        .listRowBackground(HWTheme.cardBackground)
    }

    private var clearDataSection: some View {
        Section {
            Button(role: .destructive) {
                showingClearConfirmation = true
            } label: {
                settingsRow("清空全部数据", icon: "trash", color: HWTheme.dangerRed)
            }
        } footer: {
            VStack(alignment: .leading, spacing: 24) {
                Text(appLanguage.text("会删除所有候物和存钱记录"))
                Text("\(appLanguage.text("候物 AwaitGoods")) · \(appVersion)")
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel("\(appLanguage.text("候物 AwaitGoods"))，\(appLanguage.text("版本")) \(appVersion)")
            }
        }
        .listRowBackground(HWTheme.cardBackground)
    }

    private var languageSelectionPage: some View {
        List {
            Section {
                ForEach(AppLanguage.allCases) { language in
                    selectionRow(language.title, isSelected: appLanguageRawValue == language.rawValue) {
                        appLanguageRawValue = language.rawValue
                        WidgetSyncService.sync(items: activeItems)
                    }
                }
            }
            .listRowBackground(HWTheme.cardBackground)
        }
        .settingsListStyle()
        .navigationTitle(appLanguage.text("语言"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var appearanceSelectionPage: some View {
        List {
            Section {
                ForEach(AppAppearanceMode.allCases) { mode in
                    selectionRow(appLanguage.text(mode.title), isSelected: appearanceMode == mode.rawValue) {
                        appearanceMode = mode.rawValue
                    }
                }
            }
            .listRowBackground(HWTheme.cardBackground)
        }
        .settingsListStyle()
        .navigationTitle(appLanguage.text("外观模式"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var themeSelectionPage: some View {
        List {
            Section {
                ForEach(AppTheme.allCases) { theme in
                    Button {
                        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                            appThemeRawValue = theme.rawValue
                        }
                    } label: {
                        HStack(spacing: 12) {
                            HStack(spacing: 3) {
                                ForEach(Array(theme.swatchColors.enumerated()), id: \.offset) { _, color in
                                    Capsule()
                                        .fill(color)
                                        .frame(width: 14, height: 28)
                                }
                            }
                            .accessibilityHidden(true)

                            Text(appLanguage.text(theme.title))
                                .foregroundStyle(HWTheme.primaryText)

                            Spacer(minLength: 8)
                            selectionMark(appThemeRawValue == theme.rawValue)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(appThemeRawValue == theme.rawValue ? .isSelected : [])
                }
            }
            .listRowBackground(HWTheme.cardBackground)
        }
        .settingsListStyle()
        .navigationTitle(appLanguage.text("主题配色"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func settingsRow(_ title: String, icon: String, value: String? = nil, color: Color? = nil) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(color ?? HWTheme.freshGreen)
                .frame(width: 24)
                .accessibilityHidden(true)

            Text(appLanguage.text(title))
                .foregroundStyle(color ?? HWTheme.primaryText)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 8)

            if let value {
                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(HWTheme.secondaryText)
                    .multilineTextAlignment(.trailing)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .contentShape(Rectangle())
    }

    private func externalLinkRow(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            settingsRow(title, icon: icon)
            Image(systemName: "arrow.up.right")
                .font(.caption2.weight(.medium))
                .foregroundStyle(HWTheme.tertiaryText)
                .accessibilityHidden(true)
        }
    }

    private func selectionRow(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(title)
                    .foregroundStyle(HWTheme.primaryText)
                Spacer(minLength: 8)
                selectionMark(isSelected)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func selectionMark(_ isSelected: Bool) -> some View {
        Image(systemName: "checkmark")
            .font(.body.weight(.semibold))
            .foregroundStyle(HWTheme.freshGreen)
            .opacity(isSelected ? 1 : 0)
            .accessibilityHidden(true)
    }

    private func clearAll() {
        NotificationScheduler.cancelAllWishNotifications()
        items.forEach { modelContext.delete($0) }
        try? modelContext.save()
        onChange()
    }

    private func handleImportSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            do {
                let summary = try importItems(from: url)
                dataTransferMessage = DataTransferMessage(
                    title: appLanguage.text("备份文件已导入"),
                    message: String(format: appLanguage.text("新增 %d 条 · 更新 %d 条"), summary.inserted, summary.updated)
                )
            } catch BackupImportError.emptyBackup {
                dataTransferMessage = DataTransferMessage(
                    title: appLanguage.text("无法导入备份文件"),
                    message: appLanguage.text("备份文件里没有可导入的候物")
                )
            } catch {
                dataTransferMessage = DataTransferMessage(
                    title: appLanguage.text("无法导入备份文件"),
                    message: appLanguage.text("请确认选择的是候物导出的 JSON 文件")
                )
            }

        case .failure(let error):
            if let cocoaError = error as? CocoaError, cocoaError.code == .userCancelled {
                return
            }

            dataTransferMessage = DataTransferMessage(
                title: appLanguage.text("无法导入备份文件"),
                message: appLanguage.text("请确认选择的是候物导出的 JSON 文件")
            )
        }
    }

    private func importItems(from url: URL) throws -> (inserted: Int, updated: Int) {
        let hasSecurityAccess = url.startAccessingSecurityScopedResource()
        defer {
            if hasSecurityAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let data = try Data(contentsOf: url)
        let importedItems = try JSONDecoder.backupFile.decode([WishItemExport].self, from: data)

        guard !importedItems.isEmpty else {
            throw BackupImportError.emptyBackup
        }

        var existingItemsByID = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
        var inserted = 0
        var updated = 0

        for importedItem in importedItems {
            if let existingItem = existingItemsByID[importedItem.id] {
                importedItem.apply(to: existingItem)
                updated += 1
            } else {
                let restoredItem = importedItem.makeWishItem()
                modelContext.insert(restoredItem)
                existingItemsByID[restoredItem.id] = restoredItem
                inserted += 1
            }
        }

        try modelContext.save()
        Task { await NotificationScheduler.synchronize(items: Array(existingItemsByID.values)) }
        onChange()
        return (inserted, updated)
    }

    private func makeExportFile() -> URL? {
        let exportItems = activeItems.map(WishItemExport.init)

        do {
            let data = try JSONEncoder.prettyPrinted.encode(exportItems)
            let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("await-goods-v1-export.json")
            try data.write(to: fileURL, options: [.atomic])
            return fileURL
        } catch {
            return nil
        }
    }
}

private struct WishItemExport: Codable {
    let id: UUID
    let title: String
    let price: Double?
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
    let createdAt: Date
    let updatedAt: Date

    init(item: WishItem) {
        id = item.id
        title = item.title
        price = item.price
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
        createdAt = item.createdAt
        updatedAt = item.updatedAt
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
            createdAt: createdAt,
            updatedAt: updatedAt,
            targetDate: reminderDate,
            notifyEnabled: notifyEnabled == true && reminderDate != nil && WishItemStatus.fromBackupValue(status) == .waiting,
            savedAmount: normalizedSavedAmount,
            photoData: photoData
        )
    }

    func apply(to item: WishItem) {
        item.title = trimmedTitle
        item.price = normalizedPrice
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
        item.createdAt = createdAt
        item.updatedAt = updatedAt
        item.trashedAt = nil
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

private struct DataTransferMessage: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

private enum BackupImportError: Error {
    case emptyBackup
}

private extension JSONEncoder {
    static var prettyPrinted: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

private extension JSONDecoder {
    static var backupFile: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
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

private extension View {
    func settingsListStyle() -> some View {
        listStyle(.insetGrouped)
            .listSectionSpacing(.compact)
            .environment(\.defaultMinListRowHeight, 52)
            .scrollContentBackground(.hidden)
            .background(HWTheme.pageBackground.ignoresSafeArea())
            .tint(HWTheme.freshGreen)
    }
}

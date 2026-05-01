import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.appLanguage) private var appLanguage
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("appearanceMode") private var appearanceMode = AppAppearanceMode.system.rawValue
    @AppStorage("appLanguage") private var appLanguageRawValue = AppLanguage.zhHans.rawValue

    let items: [WishItem]
    let onChange: () -> Void

    @State private var exportURL: URL?
    @State private var showingImporter = false
    @State private var showingClearConfirmation = false
    @State private var dataTransferMessage: DataTransferMessage?
    @State private var wechatIDCopied = false

    var showsDoneButton = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    settingsSection(appLanguage.text("日常偏好"), subtitle: appLanguage.text("默认值轻一点，记录就不会有负担")) {
                        languageSelector
                        appearanceSelector
                        widgetCounter
                    }

                    settingsSection(appLanguage.text("数据"), subtitle: appLanguage.text("留一份记录，也可以随时清空")) {
                        settingsActionRow(appLanguage.text("导入备份文件"), subtitle: appLanguage.text("从 JSON 恢复或合并候物"), icon: "square.and.arrow.down", color: HWTheme.freshGreen) {
                            showingImporter = true
                        }

                        settingsActionRow(appLanguage.text("生成导出文件"), subtitle: appLanguage.text("保存为 JSON 备份"), icon: "doc.badge.arrow.up", color: HWTheme.linkBlue) {
                            exportURL = makeExportFile()
                        }

                        if let exportURL {
                            ShareLink(item: exportURL) {
                                HStack(spacing: 11) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 15, weight: .regular))
                                        .foregroundStyle(HWTheme.freshGreen)

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(appLanguage.text("分享导出文件"))
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundStyle(HWTheme.primaryText)

                                        Text(appLanguage.text("文件已生成，可以发送或存到 iCloud"))
                                            .font(.system(size: 12))
                                            .foregroundStyle(HWTheme.secondaryText)
                                    }

                                    Spacer()
                                }
                                .padding(10)
                                .background(HWTheme.fieldBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                        }

                        settingsActionRow(appLanguage.text("清空全部数据"), subtitle: appLanguage.text("会删除所有候物和存钱记录"), icon: "trash", color: HWTheme.dangerRed, isDestructive: true) {
                            showingClearConfirmation = true
                        }
                    }

                    contactCard
                    appInfoCard
                }
                .padding(14)
                .padding(.top, 6)
                .padding(.bottom, 18)
            }
            .background(HWTheme.pageBackground.ignoresSafeArea())
            .navigationTitle(appLanguage.text("设置"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if showsDoneButton {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(appLanguage.text("完成")) { dismiss() }
                            .fontWeight(.medium)
                            .foregroundStyle(HWTheme.freshGreen)
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

    private var languageSelector: some View {
        VStack(alignment: .leading, spacing: 7) {
            rowTitle(appLanguage.text("语言"), icon: "globe.asia.australia")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(AppLanguage.allCases) { language in
                        chip(language.title, isSelected: appLanguageRawValue == language.rawValue) {
                            appLanguageRawValue = language.rawValue
                        }
                    }
                }
            }
        }
    }

    private func settingsSection<Content: View>(_ title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(HWTheme.primaryText)

                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(HWTheme.secondaryText)
            }

            content()
        }
        .softCard()
    }

    private var appearanceSelector: some View {
        VStack(alignment: .leading, spacing: 7) {
            rowTitle(appLanguage.text("外观模式"), icon: "sparkles")

            HStack(spacing: 6) {
                ForEach(AppAppearanceMode.allCases) { mode in
                    chip(appLanguage.text(mode.title), isSelected: appearanceMode == mode.rawValue) {
                        appearanceMode = mode.rawValue
                    }
                }
            }
        }
    }

    private var widgetCounter: some View {
        HStack(spacing: 10) {
            rowIcon("rectangle.stack")

            VStack(alignment: .leading, spacing: 3) {
                Text(appLanguage.text("小组件展示"))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(HWTheme.primaryText)

                Text(appLanguage.text("小号 1 件 · 中号 3 件 · 大号 5 件"))
                    .font(.system(size: 12))
                    .foregroundStyle(HWTheme.secondaryText)
            }

            Spacer()

            Image(systemName: "checkmark.circle")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(HWTheme.freshGreen)
        }
        .padding(10)
        .background(HWTheme.fieldBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func softToggle(title: String, subtitle: String, icon: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: 10) {
                rowIcon(icon)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(HWTheme.primaryText)

                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(HWTheme.secondaryText)
                }
            }
        }
        .tint(HWTheme.freshGreen)
        .padding(10)
        .background(HWTheme.fieldBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func rowTitle(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            rowIcon(icon)
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(HWTheme.primaryText)
        }
    }

    private func rowIcon(_ icon: String) -> some View {
        Image(systemName: icon)
            .font(.system(size: 14, weight: .regular))
            .foregroundStyle(HWTheme.freshGreen)
            .frame(width: 24, height: 24)
    }

    private func chip(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .medium : .regular))
                .foregroundStyle(isSelected ? HWTheme.cardBackground : HWTheme.secondaryText)
                .padding(.horizontal, 11)
                .padding(.vertical, 6)
                .background(isSelected ? HWTheme.freshGreen.opacity(0.82) : HWTheme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func counterButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(HWTheme.freshGreen)
                .frame(width: 28, height: 28)
                .background(HWTheme.mint.opacity(0.22))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func settingsActionRow(_ title: String, subtitle: String, icon: String, color: Color, isDestructive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(color)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(isDestructive ? HWTheme.dangerRed : HWTheme.primaryText)

                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(HWTheme.secondaryText)
                }

                Spacer()
            }
            .padding(10)
            .background(HWTheme.fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var contactCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(appLanguage.text("联系客服"))
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(HWTheme.primaryText)
                Text(appLanguage.text("有任何问题或建议，欢迎联系我们。"))
                    .font(.system(size: 13))
                    .foregroundStyle(HWTheme.secondaryText)
            }

            Button {
                UIPasteboard.general.string = "Zhuyokin"
                wechatIDCopied = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    wechatIDCopied = false
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(HWTheme.freshGreen)
                        .frame(width: 24, height: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(appLanguage.text("微信"))
                            .font(.system(size: 12))
                            .foregroundStyle(HWTheme.secondaryText)
                        Text("Zhuyokin")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(HWTheme.primaryText)
                    }

                    Spacer()

                    Text(wechatIDCopied ? appLanguage.text("已复制") : appLanguage.text("点击复制"))
                        .font(.system(size: 12))
                        .foregroundStyle(wechatIDCopied ? HWTheme.freshGreen : HWTheme.tertiaryText)
                        .animation(.easeInOut(duration: 0.2), value: wechatIDCopied)
                }
                .padding(10)
                .background(HWTheme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .softCard()
    }

    private var appInfoCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(appLanguage.text("关于 App"))
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(HWTheme.primaryText)

            HStack(spacing: 10) {
                Image(systemName: "bag")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(HWTheme.freshGreen)
                    .frame(width: 40, height: 40)
                    .background(HWTheme.mint.opacity(0.22))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(appLanguage.text("候物 AwaitGoods"))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(HWTheme.primaryText)

                    Text("v1.0.3 · \(appLanguage.text("慢慢存，轻轻买"))")
                        .font(.system(size: 13))
                        .foregroundStyle(HWTheme.secondaryText)
                }

                Spacer(minLength: 0)
            }
        }
        .softCard()
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
        onChange()
        return (inserted, updated)
    }

    private func makeExportFile() -> URL? {
        let exportItems = items.map(WishItemExport.init)

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
        savedAmount = item.savedAmountValue
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
            notifyEnabled: false,
            savedAmount: normalizedSavedAmount
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
        item.savedAmountValue = normalizedSavedAmount
        item.sortIndex = sortIndex
        item.createdAt = createdAt
        item.updatedAt = updatedAt
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
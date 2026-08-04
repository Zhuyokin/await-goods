import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.appLanguage) private var appLanguage
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("appearanceMode") private var appearanceMode = AppAppearanceMode.system.rawValue
    @AppStorage("appLanguage") private var appLanguageRawValue = AppLanguage.zhHans.rawValue
    @AppStorage(AppTheme.storageKey) private var appThemeRawValue = AppTheme.springPaper.rawValue

    let items: [WishItem]
    let onChange: () -> Void

    @State private var exportURL: URL?
    @State private var showingImporter = false
    @State private var showingClearConfirmation = false
    @State private var dataTransferMessage: DataTransferMessage?
    @State private var emailCopied = false
    @State private var contactToastVisible = false
    @State private var contactToastToken = UUID()
    private let supportEmail = "yokinzhu@gmail.com"
    private let developerPageURL = URL(string: "https://apps.apple.com/developer/%E8%A3%95%E9%87%91-%E6%9C%B1/id1888184686")

    var showsDoneButton = false
    private var activeItems: [WishItem] { items.filter { !$0.isTrashed } }
    private var currentLanguage: AppLanguage { AppLanguage(rawValue: appLanguageRawValue) ?? .zhHans }
    private var currentAppearanceMode: AppAppearanceMode { AppAppearanceMode(rawValue: appearanceMode) ?? .system }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    settingsSection(appLanguage.text("通用与偏好"), subtitle: appLanguage.text("当前选择一目了然，需要时再进入调整")) {
                        languageSelector
                        appearanceSelector
                        themeSelector
                        widgetCounter
                    }

                    settingsSection(appLanguage.text("数据与安全"), subtitle: appLanguage.text("留一份记录，也可以随时清空")) {
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
            .overlay(alignment: .bottom) { contactToast }
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
        NavigationLink {
            languageSelectionPage
        } label: {
            settingsNavigationLabel(
                appLanguage.text("语言"),
                icon: "globe.asia.australia",
                value: currentLanguage.title
            )
        }
        .buttonStyle(.plain)
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
        .settingsGroup()
    }

    @ViewBuilder
    private var contactToast: some View {
        if contactToastVisible {
            Label(appLanguage.text("邮箱地址已复制"), systemImage: "checkmark.circle.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(HWTheme.cardBackground)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(HWTheme.primaryText.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: HWTheme.softShadow, radius: 8, x: 0, y: 4)
                .padding(.bottom, 18)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private var appearanceSelector: some View {
        NavigationLink {
            appearanceSelectionPage
        } label: {
            settingsNavigationLabel(
                appLanguage.text("外观模式"),
                icon: "sparkles",
                value: appLanguage.text(currentAppearanceMode.title)
            )
        }
        .buttonStyle(.plain)
    }

    private var languageSelectionPage: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(AppLanguage.allCases) { language in
                    selectionRow(language.title, isSelected: appLanguageRawValue == language.rawValue) {
                        appLanguageRawValue = language.rawValue
                        WidgetSyncService.sync(items: activeItems)
                    }
                }
            }
            .padding(14)
        }
        .background(HWTheme.pageBackground.ignoresSafeArea())
        .navigationTitle(appLanguage.text("语言"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var appearanceSelectionPage: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(AppAppearanceMode.allCases) { mode in
                    selectionRow(appLanguage.text(mode.title), isSelected: appearanceMode == mode.rawValue) {
                        appearanceMode = mode.rawValue
                    }
                }
            }
            .padding(14)
        }
        .background(HWTheme.pageBackground.ignoresSafeArea())
        .navigationTitle(appLanguage.text("外观模式"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var themeSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            rowTitle(appLanguage.text("主题配色"), icon: "paintpalette")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 9) {
                    ForEach(AppTheme.allCases) { theme in
                        themeCard(theme)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func themeCard(_ theme: AppTheme) -> some View {
        let isSelected = appThemeRawValue == theme.rawValue

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                appThemeRawValue = theme.rawValue
            }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 7) {
                    Image(systemName: theme.icon)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(isSelected ? HWTheme.cardBackground : HWTheme.freshGreen)
                        .frame(width: 26, height: 26)
                        .background(isSelected ? HWTheme.freshGreen : HWTheme.cardBackground.opacity(0.92))
                        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

                    Spacer(minLength: 6)

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(HWTheme.freshGreen)
                    }
                }

                HStack(spacing: -3) {
                    ForEach(Array(theme.swatchColors.enumerated()), id: \.offset) { _, color in
                        Circle()
                            .fill(color)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle()
                                    .stroke(HWTheme.cardBackground.opacity(0.88), lineWidth: 1)
                            )
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(appLanguage.text(theme.title))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(HWTheme.primaryText)
                        .lineLimit(1)

                    Text(appLanguage.text(theme.subtitle))
                        .font(.system(size: 11))
                        .foregroundStyle(HWTheme.secondaryText)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(11)
            .frame(width: 154, alignment: .topLeading)
            .frame(minHeight: 118, alignment: .topLeading)
            .background(isSelected ? HWTheme.mint.opacity(0.25) : HWTheme.fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? HWTheme.freshGreen.opacity(0.58) : HWTheme.cardBorder.opacity(0.56), lineWidth: 0.9)
            )
        }
        .buttonStyle(.plain)
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

    private func settingsNavigationLabel(_ title: String, icon: String, value: String) -> some View {
        HStack(spacing: 10) {
            rowIcon(icon)

            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(HWTheme.primaryText)

            Spacer()

            Text(value)
                .font(.system(size: 13))
                .foregroundStyle(HWTheme.secondaryText)
                .lineLimit(1)

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(HWTheme.tertiaryText)
        }
        .padding(10)
        .background(HWTheme.fieldBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func selectionRow(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(HWTheme.primaryText)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(HWTheme.freshGreen)
                }
            }
            .padding(14)
            .background(HWTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? HWTheme.freshGreen.opacity(0.46) : HWTheme.cardBorder.opacity(0.44), lineWidth: 0.8)
            )
        }
        .buttonStyle(.plain)
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

                Image(systemName: isDestructive ? "exclamationmark.circle" : "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(isDestructive ? HWTheme.dangerRed : HWTheme.tertiaryText)
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

            HStack(spacing: 8) {
                if let supportEmailURL = URL(string: "mailto:\(supportEmail)") {
                    Link(destination: supportEmailURL) {
                        HStack(spacing: 10) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundStyle(HWTheme.freshGreen)
                                .frame(width: 24, height: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(appLanguage.text("邮箱支持"))
                                    .font(.system(size: 12))
                                    .foregroundStyle(HWTheme.secondaryText)
                                Text(supportEmail)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(HWTheme.primaryText)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.82)
                            }

                            Spacer(minLength: 4)

                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(HWTheme.tertiaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                }

                Button(action: copySupportEmail) {
                    Image(systemName: emailCopied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(emailCopied ? HWTheme.freshGreen : HWTheme.tertiaryText)
                        .frame(width: 32, height: 32)
                        .background(HWTheme.fieldBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(appLanguage.text("复制邮箱"))
            }
            .padding(10)
            .background(HWTheme.fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .settingsGroup()
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

                    Text("v1.0.6 · \(appLanguage.text("极简愿望清单与购物清单"))")
                        .font(.system(size: 13))
                        .foregroundStyle(HWTheme.secondaryText)
                }

                Spacer(minLength: 0)
            }

            if let developerPageURL {
                Link(destination: developerPageURL) {
                    HStack(spacing: 10) {
                        Image(systemName: "square.grid.2x2")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundStyle(HWTheme.freshGreen)
                            .frame(width: 24, height: 24)

                        Text(appLanguage.text("更多我的应用"))
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(HWTheme.primaryText)

                        Spacer()

                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(HWTheme.tertiaryText)
                    }
                    .padding(10)
                    .background(HWTheme.fieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .settingsGroup()
    }

    private func clearAll() {
        NotificationScheduler.cancelAllWishNotifications()
        items.forEach { modelContext.delete($0) }
        try? modelContext.save()
        onChange()
    }

    private func copySupportEmail() {
        UIPasteboard.general.string = supportEmail
        emailCopied = true
        showContactToast()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            emailCopied = false
        }
    }

    private func showContactToast() {
        let toastToken = UUID()
        contactToastToken = toastToken

        withAnimation(.easeInOut(duration: 0.18)) {
            contactToastVisible = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            guard contactToastToken == toastToken else { return }
            withAnimation(.easeInOut(duration: 0.18)) {
                contactToastVisible = false
            }
        }
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

private extension View {
    func settingsGroup() -> some View {
        frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(HWTheme.cardBackground.opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(HWTheme.cardBorder.opacity(0.44), lineWidth: 0.8)
            )
    }
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

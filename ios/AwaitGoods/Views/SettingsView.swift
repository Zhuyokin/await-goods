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
    @AppStorage(AppTheme.storageKey) private var appThemeRawValue = AppIllustratedTheme.current.colorTheme.rawValue
    @AppStorage(AppIllustratedTheme.storageKey) private var illustratedTheme: AppIllustratedTheme = .sakura

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
    private var currentTheme: AppTheme { AppTheme(rawValue: appThemeRawValue) ?? illustratedTheme.colorTheme }
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
                illustratedThemeSelectionPage
            } label: {
                settingsRow("主题", icon: "photo", value: appLanguage.text(illustratedTheme.title))
            }

            NavigationLink {
                themeSelectionPage
            } label: {
                settingsRow("配色", icon: "paintpalette", value: appLanguage.text(currentTheme.title))
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
            NavigationLink {
                SharePostersView()
            } label: {
                settingsRow("分享 App", icon: "square.and.arrow.up")
            }

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
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(theme.swatchColor)
                                .frame(width: 32, height: 32)
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
        .navigationTitle(appLanguage.text("配色"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var illustratedThemeSelectionPage: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 18)], spacing: 18) {
                ForEach(AppIllustratedTheme.allCases) { theme in
                    Button {
                        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                            illustratedTheme = theme
                            appThemeRawValue = theme.colorTheme.rawValue
                        }
                    } label: {
                        VStack(spacing: 0) {
                            themePreview(theme)
                            HStack(spacing: 12) {
                                Text(appLanguage.text(theme.title))
                                    .font(.headline)
                                    .foregroundStyle(HWTheme.primaryText)
                                HStack(spacing: 4) {
                                    ForEach(Array(theme.colorTheme.swatchColors.enumerated()), id: \.offset) { _, color in
                                        Circle().fill(color).frame(width: 10, height: 10)
                                    }
                                }
                                .accessibilityHidden(true)
                                Spacer()
                                selectionMark(illustratedTheme == theme)
                            }
                            .padding(18)
                        }
                        .background(HWTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .overlay {
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(illustratedTheme == theme ? HWTheme.freshGreen : HWTheme.cardBorder.opacity(0.4), lineWidth: illustratedTheme == theme ? 1.5 : 0.5)
                        }
                        .contentShape(RoundedRectangle(cornerRadius: 22))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(appLanguage.text(theme.title))
                    .accessibilityAddTraits(illustratedTheme == theme ? .isSelected : [])
                }
            }
            .padding(20)
            .frame(maxWidth: 900)
            .frame(maxWidth: .infinity)
        }
        .background { IllustrationBackdrop() }
        .navigationTitle(appLanguage.text("主题"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func themePreview(_ theme: AppIllustratedTheme) -> some View {
        ZStack {
            theme.colorTheme.previewBackground
            Image(theme.emptyStateAssetName)
                .resizable().scaledToFit()
                .frame(width: 156, height: 156)
        }
        .overlay(alignment: .topTrailing) {
            Image(theme.topAssetName)
                .resizable().scaledToFit()
                .frame(width: 145, height: 145)
                .opacity(0.48)
                .offset(x: 14, y: -18)
        }
        .overlay(alignment: .bottomLeading) {
            Image(theme.bottomAssetName)
                .resizable().scaledToFit()
                .frame(width: 150, height: 150)
                .opacity(0.48)
                .offset(x: -18, y: 6)
        }
        .frame(height: 204)
        .clipped()
        .accessibilityHidden(true)
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
            } catch BackupImportError.unsupportedCurrency(let code) {
                dataTransferMessage = DataTransferMessage(
                    title: appLanguage.text("无法导入备份文件"),
                    message: String(format: appLanguage.text("备份包含暂不支持的币种：%@。"), code)
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
        if let unsupported = importedItems.first(where: { WishCurrency(rawValue: $0.resolvedCurrencyCode) == nil }) {
            throw BackupImportError.unsupportedCurrency(unsupported.resolvedCurrencyCode)
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

private struct DataTransferMessage: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

private enum BackupImportError: Error {
    case emptyBackup
    case unsupportedCurrency(String)
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

private extension View {
    func settingsListStyle() -> some View {
        listStyle(.insetGrouped)
            .listSectionSpacing(.compact)
            .environment(\.defaultMinListRowHeight, 52)
            .scrollContentBackground(.hidden)
            .background { IllustrationBackdrop() }
            .tint(HWTheme.freshGreen)
    }
}

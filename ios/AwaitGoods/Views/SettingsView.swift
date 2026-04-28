import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.appLanguage) private var appLanguage
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("appearanceMode") private var appearanceMode = AppAppearanceMode.system.rawValue
    @AppStorage("appLanguage") private var appLanguageRawValue = AppLanguage.zhHans.rawValue

    let items: [WishItem]
    let onChange: () -> Void

    @State private var exportURL: URL?
    @State private var showingClearConfirmation = false
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
        }
    }

    private var languageSelector: some View {
        VStack(alignment: .leading, spacing: 7) {
            rowTitle(appLanguage.text("语言"), icon: "globe.asia.australia")

            HStack(spacing: 6) {
                ForEach(AppLanguage.allCases) { language in
                    chip(language.title, isSelected: appLanguageRawValue == language.rawValue) {
                        appLanguageRawValue = language.rawValue
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

                    Text(appLanguage.text("v1.0 · 慢慢存，轻轻买"))
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
        priority = item.priority.title
        status = item.status.title
        markColor = item.markColor.title
        savedAmount = item.savedAmountValue
        sortIndex = item.sortIndex
        createdAt = item.createdAt
        updatedAt = item.updatedAt
    }
}

private extension JSONEncoder {
    static var prettyPrinted: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}
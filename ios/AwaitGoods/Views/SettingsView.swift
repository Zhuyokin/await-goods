import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("defaultWaitDays") private var defaultWaitDays = DefaultWaitPeriod.seven.rawValue
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("appearanceMode") private var appearanceMode = AppAppearanceMode.system.rawValue
    @AppStorage("widgetItemLimit") private var widgetItemLimit = 3

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
                    settingsHeader

                    settingsSection("日常偏好", subtitle: "默认值轻一点，记录就不会有负担") {
                        waitPeriodSelector
                        softToggle(title: "通知提醒", subtitle: "只在冷静期结束时轻轻提醒", icon: "bell", isOn: $notificationsEnabled)
                        appearanceSelector
                        widgetCounter
                    }

                    settingsSection("数据", subtitle: "留一份记录，也可以随时清空") {
                        settingsActionRow("生成导出文件", subtitle: "保存为 JSON 备份", icon: "doc.badge.arrow.up", color: HWTheme.linkBlue) {
                            exportURL = makeExportFile()
                        }

                        if let exportURL {
                            ShareLink(item: exportURL) {
                                HStack(spacing: 11) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 15, weight: .regular))
                                        .foregroundStyle(HWTheme.freshGreen)

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("分享导出文件")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundStyle(HWTheme.primaryText)

                                        Text("文件已生成，可以发送或存到 iCloud")
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

                        settingsActionRow("清空全部数据", subtitle: "会删除所有候物和提醒", icon: "trash", color: HWTheme.dangerRed, isDestructive: true) {
                            showingClearConfirmation = true
                        }
                    }

                    contactCard
                    appInfoCard
                }
                .padding(14)
                .padding(.bottom, 18)
            }
            .background(HWTheme.pageBackground.ignoresSafeArea())
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if showsDoneButton {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("完成") { dismiss() }
                            .fontWeight(.medium)
                            .foregroundStyle(HWTheme.freshGreen)
                    }
                }
            }
            .alert("所有候物都会被删除", isPresented: $showingClearConfirmation) {
                Button("取消", role: .cancel) { }
                Button("清空", role: .destructive) { clearAll() }
            }
            .onChange(of: notificationsEnabled) { _, enabled in
                if !enabled {
                    NotificationScheduler.cancelAllWishNotifications()
                }
            }
            .onChange(of: widgetItemLimit) { _, _ in onChange() }
            .onAppear {
                if widgetItemLimit > 3 {
                    widgetItemLimit = 3
                    onChange()
                }
            }
        }
    }

    private var settingsHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("把候物调成舒服的样子")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(HWTheme.primaryText)

            Text("少一点打扰，多一点克制感。")
                .font(.system(size: 14))
                .foregroundStyle(HWTheme.secondaryText)
        }
        .padding(.top, 6)
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

    private var waitPeriodSelector: some View {
        VStack(alignment: .leading, spacing: 7) {
            rowTitle("默认等待期", icon: "hourglass")

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 6)], spacing: 6) {
                ForEach(DefaultWaitPeriod.allCases) { period in
                    chip(period.title, isSelected: defaultWaitDays == period.rawValue) {
                        defaultWaitDays = period.rawValue
                    }
                }
            }
        }
    }

    private var appearanceSelector: some View {
        VStack(alignment: .leading, spacing: 7) {
            rowTitle("外观模式", icon: "sparkles")

            HStack(spacing: 6) {
                ForEach(AppAppearanceMode.allCases) { mode in
                    chip(mode.title, isSelected: appearanceMode == mode.rawValue) {
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
                Text("小组件展示")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(HWTheme.primaryText)

                Text("最多展示 \(widgetItemLimit) 件正在等的东西")
                    .font(.system(size: 12))
                    .foregroundStyle(HWTheme.secondaryText)
            }

            Spacer()

            HStack(spacing: 8) {
                counterButton("minus") { widgetItemLimit = max(1, widgetItemLimit - 1) }
                    .disabled(widgetItemLimit <= 1)

                Text("\(widgetItemLimit)")
                    .font(.system(size: 16, weight: .medium).monospacedDigit())
                    .foregroundStyle(HWTheme.primaryText)
                    .padding(.horizontal, 3)

                counterButton("plus") { widgetItemLimit = min(3, widgetItemLimit + 1) }
                    .disabled(widgetItemLimit >= 3)
            }
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
                Text("联系客服")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(HWTheme.primaryText)
                Text("有任何问题或建议，欢迎联系我们。")
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
                        Text("微信")
                            .font(.system(size: 12))
                            .foregroundStyle(HWTheme.secondaryText)
                        Text("Zhuyokin")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(HWTheme.primaryText)
                    }

                    Spacer()

                    Text(wechatIDCopied ? "已复制" : "点击复制")
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
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "bag")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(HWTheme.freshGreen)
                    .frame(width: 40, height: 40)
                    .background(HWTheme.mint.opacity(0.22))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text("候物 AwaitGoods")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(HWTheme.primaryText)

                    Text("v1.0 · 等一等，再入手")
                        .font(.system(size: 13))
                        .foregroundStyle(HWTheme.secondaryText)
                }
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
    let sortIndex: Int
    let createdAt: Date
    let updatedAt: Date
    let waitUntil: Date?
    let targetDate: Date?
    let notifyEnabled: Bool

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
        sortIndex = item.sortIndex
        createdAt = item.createdAt
        updatedAt = item.updatedAt
        waitUntil = item.waitUntil
        targetDate = item.targetDate
        notifyEnabled = item.notifyEnabled
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
import SwiftData
import SwiftUI
import UIKit

struct WishEditorView: View {
    @Environment(\.appLanguage) private var appLanguage
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let item: WishItem?
    let existingItems: [WishItem]
    let onSave: (WishItem) -> Void

    @State private var photoData: Data?
    @State private var isPhotoLoading = false
    @State private var title: String
    @State private var priceText: String
    @State private var savedText: String
    @State private var linkString: String
    @State private var category: String
    @State private var priority: WishPriority
    @State private var note: String
    @State private var markColor: MarkColor
    @State private var notifyEnabled: Bool
    @State private var reminderDate: Date
    @State private var showsMore: Bool
    @State private var showingNotificationPermissionAlert = false

    init(
        item: WishItem?,
        existingItems: [WishItem],
        onSave: @escaping (WishItem) -> Void
    ) {
        self.item = item
        self.existingItems = existingItems
        self.onSave = onSave

        _photoData = State(initialValue: item?.photoData)
        _title = State(initialValue: item?.title ?? "")
        _priceText = State(initialValue: item?.price.map { String(format: "%.2f", $0) } ?? "")
        _savedText = State(initialValue: (item?.savedAmountValue ?? 0) > 0 ? String(format: "%.2f", item?.savedAmountValue ?? 0) : "")
        _linkString = State(initialValue: item?.linkString ?? "")
        _category = State(initialValue: item?.category ?? "")
        _priority = State(initialValue: item?.priority ?? .medium)
        let now = Date()
        let existingReminderDate = item?.targetDate ?? item?.waitUntil
        let defaultReminderDate = Self.defaultReminderDate(after: now)

        _note = State(initialValue: item?.note ?? "")
        _markColor = State(initialValue: item?.markColor ?? .none)
        _notifyEnabled = State(initialValue: item?.notifyEnabled == true && (existingReminderDate ?? .distantPast) > now)
        _reminderDate = State(initialValue: (existingReminderDate ?? .distantPast) > now ? existingReminderDate! : defaultReminderDate)
        _showsMore = State(initialValue: item != nil && (!(item?.linkString.isEmpty ?? true) || !(item?.note.isEmpty ?? true) || (item?.markColor ?? .none) != .none || item?.notifyEnabled == true))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                identitySection
                budgetSection
                categorySection
                moreSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 20)
            .frame(maxWidth: 660)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .background { IllustrationBackdrop() }
        .safeAreaInset(edge: .bottom) { saveButton }
        .navigationTitle(appLanguage.text(item == nil ? "添加心愿" : "编辑心愿"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(HWTheme.pageBackground, for: .navigationBar)
        .tint(HWTheme.freshGreen)
        .alert(appLanguage.text("提醒权限未开启"), isPresented: $showingNotificationPermissionAlert) {
            Button(appLanguage.text("稍后"), role: .cancel) { }
            Button(appLanguage.text("去设置")) { openNotificationSettings() }
        } message: {
            Text(appLanguage.text("请在系统设置中允许候物发送通知。"))
        }
    }

    private var identitySection: some View {
        HStack(spacing: 17) {
            WishPhotoPicker(photoData: $photoData, isLoading: $isPhotoLoading)
            VStack(alignment: .leading, spacing: 10) {
                Text(appLanguage.text("心愿名称"))
                    .font(.system(size: 12))
                    .foregroundStyle(HWTheme.secondaryText)
                TextField(appLanguage.text("比如 AirPods、通勤包"), text: $title, axis: .vertical)
                    .font(.system(size: 21, weight: .medium))
                    .lineLimit(1...3)
                    .foregroundStyle(HWTheme.primaryText)
                    .accessibilityLabel(appLanguage.text("心愿名称"))
                Divider().overlay(HWTheme.freshGreen.opacity(0.15))
                if photoData != nil {
                    Button(appLanguage.text("移除图片")) { photoData = nil }
                        .font(.system(size: 12))
                        .disabled(isPhotoLoading)
                } else {
                    Text(appLanguage.text("只填名称，也可以先记下来"))
                        .font(.system(size: 11))
                        .foregroundStyle(HWTheme.secondaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 9)
    }

    private var budgetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 18) {
                amountField("目标价格", placeholder: appLanguage.text("可选"), text: $priceText)
                Rectangle().fill(HWTheme.separator.opacity(0.4)).frame(width: 1, height: 45)
                amountField("已存金额", placeholder: "0", text: $savedText)
            }
            if let amountValidationMessage {
                Text(amountValidationMessage)
                    .font(.system(size: 12))
                    .foregroundStyle(HWTheme.dangerRed)
            } else if parsedPrice != nil {
                Divider().overlay(HWTheme.separator.opacity(0.4))
                HStack {
                    Text(savingsStatusText).foregroundStyle(HWTheme.secondaryText)
                    Spacer()
                    Text("\(Int((previewProgress * 100).rounded()))%")
                        .foregroundStyle(HWTheme.freshGreen)
                }
                .font(.system(size: 12).monospacedDigit())
                ProgressView(value: previewProgress).tint(HWTheme.freshGreen)
            }
        }
        .padding(18)
        .background(HWTheme.cardBackground, in: RoundedRectangle(cornerRadius: 20))
    }

    private func amountField(_ label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(appLanguage.text(label))
                .font(.system(size: 12))
                .foregroundStyle(HWTheme.secondaryText)
            HStack(spacing: 6) {
                Text("$").foregroundStyle(HWTheme.freshGreen)
                TextField(placeholder, text: text)
                    .keyboardType(.decimalPad)
                    .foregroundStyle(HWTheme.primaryText)
                    .accessibilityLabel(appLanguage.text(label))
            }
            .font(.system(size: 21, weight: .medium).monospacedDigit())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Text(appLanguage.text("分类")).fontWeight(.medium)
                TextField(appLanguage.text("可选"), text: $category)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(HWTheme.freshGreen)
                    .accessibilityLabel(appLanguage.text("分类"))
                Image(systemName: "pencil")
                    .font(.system(size: 12))
                    .foregroundStyle(HWTheme.secondaryText)
                    .accessibilityHidden(true)
            }
            .font(.system(size: 14))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(WishCategoryCatalog.suggestions(from: existingItems, including: category), id: \.self) { suggestion in
                        Button { category = suggestion } label: {
                            Text(appLanguage.text(suggestion))
                                .font(.system(size: 12, weight: trimmedCategory == suggestion ? .medium : .regular))
                                .foregroundStyle(trimmedCategory == suggestion ? HWTheme.freshGreen : HWTheme.secondaryText)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 9)
                                .background(trimmedCategory == suggestion ? HWTheme.mint.opacity(0.3) : HWTheme.fieldBackground, in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(trimmedCategory == suggestion ? .isSelected : [])
                    }
                }
            }
            Divider().overlay(HWTheme.separator.opacity(0.4))
            HStack(spacing: 14) {
                Text(appLanguage.text("优先级"))
                    .font(.system(size: 14, weight: .medium))
                Spacer(minLength: 0)
                Picker(appLanguage.text("优先级"), selection: $priority) {
                    ForEach(WishPriority.allCases) { value in
                        Text(appLanguage.text(value.title)).tag(value)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 180)
            }
        }
        .foregroundStyle(HWTheme.primaryText)
        .padding(18)
        .background(HWTheme.cardBackground, in: RoundedRectangle(cornerRadius: 20))
    }

    private var moreSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { showsMore.toggle() }
            } label: {
                HStack(spacing: 10) {
                    Text(appLanguage.text("更多信息"))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(HWTheme.primaryText)
                    Spacer(minLength: 0)
                    Text(appLanguage.text(showsMore ? "收起" : "链接、备注、提醒"))
                        .font(.system(size: 12))
                    Image(systemName: showsMore ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(HWTheme.secondaryText)
                .frame(minHeight: 24)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityValue(appLanguage.text(showsMore ? "收起" : "链接、备注、提醒"))

            if showsMore {
                Divider().overlay(HWTheme.separator.opacity(0.4))
                HStack(spacing: 10) {
                    Image(systemName: "link").foregroundStyle(HWTheme.freshGreen)
                    TextField(appLanguage.text("商品链接，可选"), text: $linkString)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .accessibilityLabel(appLanguage.text("商品链接"))
                }
                .font(.system(size: 14))
                .padding(.vertical, 4)
                TextField(appLanguage.text("为什么想买？现在担心什么？"), text: $note, axis: .vertical)
                    .lineLimit(2...6)
                    .font(.system(size: 14))
                    .padding(12)
                    .background(HWTheme.fieldBackground, in: RoundedRectangle(cornerRadius: 12))
                    .accessibilityLabel(appLanguage.text("备注"))
                markColorSelector
                Divider().overlay(HWTheme.separator.opacity(0.4))
                reminderSelector
            }
        }
        .foregroundStyle(HWTheme.primaryText)
        .padding(18)
        .background(HWTheme.cardBackground, in: RoundedRectangle(cornerRadius: 20))
    }

    private var markColorSelector: some View {
        HStack(spacing: 4) {
            Text(appLanguage.text("标记色")).font(.system(size: 14))
            Spacer(minLength: 4)
            ForEach(MarkColor.allCases) { color in
                Button { markColor = color } label: {
                    Circle()
                        .fill(HWTheme.markColor(color))
                        .overlay {
                            if color == .none {
                                Circle().strokeBorder(HWTheme.tertiaryText.opacity(0.5), lineWidth: 1)
                            }
                            if markColor == color {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(HWTheme.primaryText)
                            }
                        }
                        .frame(width: 24, height: 24)
                        .frame(width: 36, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(appLanguage.text(color.title))
                .accessibilityAddTraits(markColor == color ? .isSelected : [])
            }
        }
    }

    private var reminderSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: reminderToggleBinding) {
                Label {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(appLanguage.text("提醒我再做决定")).font(.system(size: 14))
                        Text(appLanguage.text("无需网络，到点仅提醒一次"))
                            .font(.system(size: 11))
                            .foregroundStyle(HWTheme.secondaryText)
                    }
                } icon: {
                    Image(systemName: "bell").foregroundStyle(HWTheme.freshGreen)
                }
            }
            if notifyEnabled {
                DatePicker(
                    appLanguage.text("提醒时间"),
                    selection: $reminderDate,
                    in: minimumReminderDate...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var saveButton: some View {
        Button(action: save) {
            Text(appLanguage.text(item == nil ? "加入心愿清单" : "保存修改"))
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 54)
                .background(canSave ? HWTheme.freshGreen : HWTheme.tertiaryText, in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .disabled(!canSave)
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .frame(maxWidth: 660)
        .frame(maxWidth: .infinity)
        .background(HWTheme.pageBackground)
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedCategory: String {
        category.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var parsedPrice: Double? {
        normalizedAmount(from: priceText)
    }

    private var parsedSavedAmount: Double {
        normalizedAmount(from: savedText) ?? 0
    }

    private var amountValidationMessage: String? {
        let hasPrice = !priceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasSaved = !savedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        if hasPrice && parsedPrice == nil { return appLanguage.text("价格需大于 0") }
        if hasSaved && normalizedAmount(from: savedText) == nil { return appLanguage.text("已存需大于 0") }
        if let parsedPrice, parsedSavedAmount > parsedPrice { return appLanguage.text("已存不能超过价格") }
        return nil
    }

    private var canSave: Bool {
        !trimmedTitle.isEmpty && !isPhotoLoading &&
            amountValidationMessage == nil &&
            (!notifyEnabled || reminderDate > Date())
    }

    private var minimumReminderDate: Date {
        Date().addingTimeInterval(60)
    }

    private var reminderToggleBinding: Binding<Bool> {
        Binding(
            get: { notifyEnabled },
            set: { setReminderEnabled($0) }
        )
    }

    private var previewProgress: Double {
        guard let parsedPrice, parsedPrice > 0 else { return parsedSavedAmount > 0 ? 1 : 0 }
        return min(parsedSavedAmount / parsedPrice, 1)
    }

    private var savingsStatusText: String {
        guard let parsedPrice else {
            return parsedSavedAmount > 0 ? "\(appLanguage.text("已存")) \(moneyText(parsedSavedAmount))" : appLanguage.text("目标未定")
        }

        let remaining = max(parsedPrice - parsedSavedAmount, 0)
        return remaining == 0 ? appLanguage.text("已存满") : "\(appLanguage.text("还差")) \(moneyText(remaining))"
    }

    private func save() {
        guard canSave else { return }
        let savedItem: WishItem

        if let item {
            item.photoData = photoData
            item.title = trimmedTitle
            item.price = parsedPrice
            item.savedAmountValue = parsedSavedAmount
            item.linkString = linkString.trimmingCharacters(in: .whitespacesAndNewlines)
            item.category = trimmedCategory
            item.priority = priority
            item.waitUntil = nil
            item.targetDate = notifyEnabled ? reminderDate : nil
            item.notifyEnabled = notifyEnabled
            item.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
            item.markColor = markColor
            item.reconcileSavingsStatus()
            if item.status != .waiting {
                item.notifyEnabled = false
                item.targetDate = nil
            }
            item.updatedAt = Date()
            savedItem = item
        } else {
            let nextIndex = WishSortIndexPolicy.prepareForNewItem(existingItems: existingItems)
            let newItem = WishItem(
                title: trimmedTitle,
                price: parsedPrice,
                linkString: linkString.trimmingCharacters(in: .whitespacesAndNewlines),
                note: note.trimmingCharacters(in: .whitespacesAndNewlines),
                category: trimmedCategory,
                priority: priority,
                markColor: markColor,
                sortIndex: nextIndex,
                targetDate: notifyEnabled ? reminderDate : nil,
                notifyEnabled: notifyEnabled,
                savedAmount: parsedSavedAmount,
                photoData: photoData
            )
            newItem.reconcileSavingsStatus()
            if newItem.status != .waiting {
                newItem.notifyEnabled = false
                newItem.targetDate = nil
            }
            modelContext.insert(newItem)
            savedItem = newItem
        }

        try? modelContext.save()
        Task { await NotificationScheduler.schedule(for: savedItem) }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        dismiss()
        onSave(savedItem)
    }

    private func setReminderEnabled(_ enabled: Bool) {
        guard enabled else {
            notifyEnabled = false
            return
        }

        Task { @MainActor in
            let granted = await NotificationScheduler.requestAuthorizationIfNeeded()
            notifyEnabled = granted

            if granted {
                if reminderDate <= Date() {
                    reminderDate = Self.defaultReminderDate()
                }
            } else {
                showingNotificationPermissionAlert = true
            }
        }
    }

    private func openNotificationSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private static func defaultReminderDate(after date: Date = Date()) -> Date {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: date) ?? date.addingTimeInterval(24 * 60 * 60)
        return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow) ?? tomorrow
    }

    private func normalizedAmount(from text: String) -> Double? {
        let normalized = text
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Double(normalized), value > 0 else { return nil }
        return value
    }

    private func moneyText(_ value: Double) -> String {
        "$\(value.formatted(.number.precision(.fractionLength(0...0))))"
    }
}

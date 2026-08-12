import SwiftData
import SwiftUI
import UIKit

private enum WishAddType: String, CaseIterable, Identifiable {
    case product
    case experience
    case wish
    case gift
    case daily
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .product: return "商品"
        case .experience: return "体验"
        case .wish: return "心愿"
        case .gift: return "礼物"
        case .daily: return "生活用品"
        case .other: return "其他"
        }
    }

    var subtitle: String {
        switch self {
        case .product: return "实物商品"
        case .experience: return "旅行、活动等"
        case .wish: return "愿望或目标"
        case .gift: return "送给重要的人"
        case .daily: return "日常必需品"
        case .other: return "其他类型"
        }
    }

    var icon: String {
        switch self {
        case .product: return "bag"
        case .experience: return "airplane"
        case .wish: return "star"
        case .gift: return "gift"
        case .daily: return "basket"
        case .other: return "ellipsis.circle"
        }
    }
}

struct WishEditorView: View {
    @Environment(\.appLanguage) private var appLanguage
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let item: WishItem?
    let existingItems: [WishItem]
    let embedsInNavigationStack: Bool
    let dismissOnSave: Bool
    let onCancel: (() -> Void)?
    let onSave: (WishItem) -> Void

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
    @State private var showingNotificationPermissionAlert = false
    @State private var editorStep: Int
    @State private var addType: WishAddType = .product
    @FocusState private var titleFocused: Bool

    init(
        item: WishItem?,
        existingItems: [WishItem],
        embedsInNavigationStack: Bool = true,
        dismissOnSave: Bool = true,
        onCancel: (() -> Void)? = nil,
        onSave: @escaping (WishItem) -> Void
    ) {
        self.item = item
        self.existingItems = existingItems
        self.embedsInNavigationStack = embedsInNavigationStack
        self.dismissOnSave = dismissOnSave
        self.onCancel = onCancel
        self.onSave = onSave

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
        _editorStep = State(initialValue: 0)
    }

    @ViewBuilder
    var body: some View {
        if embedsInNavigationStack {
            NavigationStack {
                editorContent
            }
        } else {
            editorContent
        }
    }

    private var editorContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                editorHeader
                stepIndicator
                currentStepContent
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
            .scrollDismissesKeyboard(.interactively)
            .background { HWCreamLeafBackdrop() }
            .navigationTitle(item == nil ? appLanguage.text("添加新物品") : appLanguage.text("编辑"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(appLanguage.text(editorStep > 0 ? "返回" : "取消")) {
                        if editorStep > 0 {
                            editorStep -= 1
                        } else {
                            cancel()
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if editorStep < lastStep {
                        Button(appLanguage.text("下一步")) { advanceStep() }
                            .foregroundStyle(HWTheme.freshGreen)
                            .disabled(!canAdvanceCurrentStep)
                    } else {
                        Button(appLanguage.text("保存")) { save() }
                            .foregroundStyle(HWTheme.freshGreen)
                            .disabled(!canSave)
                    }
                }
            }
            .onAppear {
                titleFocused = item == nil && editorStep == basicStep
            }
            .alert(appLanguage.text("提醒权限未开启"), isPresented: $showingNotificationPermissionAlert) {
                Button(appLanguage.text("稍后"), role: .cancel) { }
                Button(appLanguage.text("去设置")) { openNotificationSettings() }
            } message: {
                Text(appLanguage.text("请在系统设置中允许候物发送通知。"))
            }
    }

    private var editorHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item == nil ? appLanguage.text("添加新物品") : appLanguage.text("调整这件候物"))
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(HWTheme.primaryText)

            Text(appLanguage.text("轻松添加你的想要清单"))
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(HWTheme.secondaryText)
        }
        .padding(.top, 8)
    }

    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0...lastStep, id: \.self) { step in
                HStack(spacing: 6) {
                    Text("\(step + 1)")
                        .font(.system(size: 12, weight: .semibold).monospacedDigit())
                        .foregroundStyle(editorStep == step ? HWTheme.cardBackground : HWTheme.secondaryText)
                        .frame(width: 22, height: 22)
                        .background(editorStep == step ? HWTheme.freshGreen : HWTheme.fieldBackground)
                        .clipShape(Circle())

                    if step < lastStep {
                        Rectangle()
                            .fill(step < editorStep ? HWTheme.freshGreen.opacity(0.65) : HWTheme.separator.opacity(0.45))
                            .frame(height: 1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(appLanguage.text("添加步骤"))
    }

    @ViewBuilder
    private var currentStepContent: some View {
        if item == nil && editorStep == 0 {
            typeStep
        } else if editorStep == basicStep {
            basicInfoStep
        } else if editorStep == budgetStep {
            budgetStepContent
        } else {
            confirmationStep
        }
    }

    private var typeStep: some View {
        editorSection(appLanguage.text("选择添加方式"), subtitle: appLanguage.text("先选一个最接近的类型")) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(WishAddType.allCases) { type in
                    Button {
                        addType = type
                    } label: {
                        VStack(spacing: 9) {
                            Image(systemName: type.icon)
                                .font(.system(size: 24, weight: .regular))
                                .foregroundStyle(addType == type ? HWTheme.freshGreen : HWTheme.secondaryText)

                            Text(appLanguage.text(type.title))
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(HWTheme.primaryText)

                            Text(appLanguage.text(type.subtitle))
                                .font(.system(size: 11))
                                .foregroundStyle(HWTheme.secondaryText)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, minHeight: 100)
                        .background(addType == type ? HWTheme.mint.opacity(0.22) : HWTheme.fieldBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(addType == type ? HWTheme.freshGreen.opacity(0.55) : HWTheme.cardBorder.opacity(0.36), lineWidth: 0.8)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var basicInfoStep: some View {
        editorSection(appLanguage.text("基本信息"), subtitle: appLanguage.text("先把想要的东西记清楚")) {
            HStack(spacing: 12) {
                Image(systemName: addType.icon)
                    .font(.system(size: 28, weight: .regular))
                    .foregroundStyle(HWTheme.freshGreen)
                    .frame(width: 82, height: 82)
                    .background(HWTheme.mint.opacity(0.18))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(appLanguage.text("名称"))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(HWTheme.tertiaryText)

                    TextField(appLanguage.text("比如 AirPods、通勤包"), text: $title)
                        .font(.system(size: 17, weight: .medium))
                        .focused($titleFocused)
                }
            }
            .padding(12)
            .background(HWTheme.fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            softTextField(appLanguage.text("链接"), placeholder: appLanguage.text("商品链接，可选"), text: $linkString, icon: "link")
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            TextField(appLanguage.text("为什么想买？现在担心什么？"), text: $note, axis: .vertical)
                .lineLimit(4...8)
                .font(.system(size: 16, weight: .medium))
                .padding(14)
                .background(HWTheme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var budgetStepContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            editorSection(appLanguage.text("设置目标与分类"), subtitle: appLanguage.text("预算和优先级，让决定更清楚")) {
                HStack(spacing: 8) {
                    softTextField(appLanguage.text("价格"), placeholder: appLanguage.text("可选"), text: $priceText, icon: "dollarsign")
                        .keyboardType(.decimalPad)

                    softTextField(appLanguage.text("已存"), placeholder: appLanguage.text("可选"), text: $savedText, icon: "banknote")
                        .keyboardType(.decimalPad)
                }

                if let amountValidationMessage {
                    Text(amountValidationMessage)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(HWTheme.dangerRed)
                }

                prioritySelector
                softTextField(appLanguage.text("分类"), placeholder: appLanguage.text("可选"), text: $category, icon: "tag")
                categorySuggestions
                savingsPreview
                markColorSelector
                reminderSelector
            }
        }
    }

    private var confirmationStep: some View {
        editorSection(appLanguage.text("确认信息"), subtitle: appLanguage.text("确认后就会加入你的候物清单")) {
            VStack(spacing: 12) {
                Image(systemName: "bag.badge.plus")
                    .font(.system(size: 34, weight: .regular))
                    .foregroundStyle(HWTheme.freshGreen)
                    .frame(width: 76, height: 76)
                    .background(HWTheme.mint.opacity(0.18))
                    .clipShape(Circle())

                Text(trimmedTitle)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(HWTheme.primaryText)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)

            summaryRow(appLanguage.text("目标价格"), value: parsedPrice.map(moneyText) ?? appLanguage.text("目标未定"), icon: "target")
            summaryRow(appLanguage.text("已存金额"), value: moneyText(parsedSavedAmount), icon: "banknote")
            summaryRow(appLanguage.text("还需金额"), value: parsedPrice.map { moneyText(max($0 - parsedSavedAmount, 0)) } ?? "—", icon: "dollarsign")
            summaryRow(appLanguage.text("优先级"), value: appLanguage.text(priority.title), icon: "flag")
            summaryRow(appLanguage.text("分类"), value: trimmedCategory.isEmpty ? appLanguage.text("未分类") : appLanguage.text(trimmedCategory), icon: "tag")
            summaryRow(
                appLanguage.text("提醒"),
                value: notifyEnabled ? reminderDate.formatted(date: .abbreviated, time: .shortened) : appLanguage.text("未设置"),
                icon: "bell"
            )
        }
    }

    private func summaryRow(_ title: String, value: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(HWTheme.freshGreen)
                .frame(width: 26, height: 26)
                .background(HWTheme.mint.opacity(0.16))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            Text(title)
                .font(.system(size: 14))
                .foregroundStyle(HWTheme.secondaryText)

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .semibold).monospacedDigit())
                .foregroundStyle(HWTheme.primaryText)
                .lineLimit(1)
        }
        .padding(11)
        .background(HWTheme.fieldBackground)
        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
    }

    private func editorSection<Content: View>(_ title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(HWTheme.primaryText)

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(HWTheme.secondaryText)
                }
            }

            content()
        }
        .softCard()
    }

    private func softTextField(_ title: String, placeholder: String, text: Binding<String>, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(HWTheme.freshGreen)
                .frame(width: 34, height: 34)
                .background(HWTheme.mint.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(HWTheme.tertiaryText)

                TextField(placeholder, text: text)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(HWTheme.primaryText)
            }
        }
        .padding(14)
        .background(HWTheme.fieldBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var categorySuggestions: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(WishCategoryCatalog.suggestions(from: existingItems, including: category), id: \.self) { suggestion in
                    chipButton(appLanguage.text(suggestion), isSelected: trimmedCategory == suggestion) {
                        category = suggestion
                    }
                }
            }
        }
    }

    private var prioritySelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            selectorTitle(appLanguage.text("优先级"))

            HStack(spacing: 10) {
                ForEach(WishPriority.allCases) { value in
                    chipButton(appLanguage.text(value.title), isSelected: priority == value) {
                        priority = value
                    }
                }
            }
        }
    }

    private var savingsPreview: some View {
        VStack(alignment: .leading, spacing: 10) {
            selectorTitle(appLanguage.text("存钱进度"))

            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    Text(savingsStatusText)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(HWTheme.primaryText)

                    Spacer()

                    if parsedPrice != nil {
                        Text("\(Int((previewProgress * 100).rounded()))%")
                            .font(.system(size: 13, weight: .regular).monospacedDigit())
                            .foregroundStyle(HWTheme.secondaryText)
                    }
                }

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(HWTheme.cardBackground)
                        Capsule()
                            .fill(HWTheme.savingsProgressColor(previewProgress, isComplete: previewProgress >= 1))
                            .frame(width: proxy.size.width * previewProgress)
                    }
                }
                .frame(height: 6)
            }
            .padding(12)
            .background(HWTheme.fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var markColorSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            selectorTitle(appLanguage.text("标记色"))

            HStack(spacing: 10) {
                ForEach(MarkColor.allCases) { color in
                    Button {
                        markColor = color
                    } label: {
                        ZStack {
                            Image(systemName: color == .none ? "circle" : "circle.fill")
                                .font(.system(size: 34, weight: .regular))
                                .foregroundStyle(color == .none ? HWTheme.tertiaryText : HWTheme.markColor(color))

                            if markColor == color {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(HWTheme.primaryText)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(appLanguage.text(color.title))
                }
            }
        }
    }

    private var reminderSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            selectorTitle(appLanguage.text("本地提醒"))

            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Image(systemName: "bell")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(HWTheme.freshGreen)
                        .frame(width: 34, height: 34)
                        .background(HWTheme.mint.opacity(0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(appLanguage.text("提醒我再做决定"))
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(HWTheme.primaryText)

                        Text(appLanguage.text("无需网络，到点仅提醒一次"))
                            .font(.system(size: 12))
                            .foregroundStyle(HWTheme.secondaryText)
                    }

                    Spacer(minLength: 8)

                    Toggle("", isOn: reminderToggleBinding)
                        .labelsHidden()
                }
                .padding(12)

                if notifyEnabled {
                    Divider()
                        .overlay(HWTheme.separator.opacity(0.5))
                        .padding(.horizontal, 12)

                    DatePicker(
                        appLanguage.text("提醒时间"),
                        selection: $reminderDate,
                        in: minimumReminderDate...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .font(.system(size: 14, weight: .medium))
                    .padding(12)
                }
            }
            .background(HWTheme.fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func selectorTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .regular))
            .foregroundStyle(HWTheme.secondaryText)
    }

    private func chipButton(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .medium : .regular))
                .foregroundStyle(isSelected ? HWTheme.cardBackground : HWTheme.secondaryText)
                .padding(.horizontal, 18)
                .padding(.vertical, 11)
                .background(isSelected ? HWTheme.freshGreen.opacity(0.82) : HWTheme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: isSelected ? HWTheme.freshGreen.opacity(0.18) : .clear, radius: 7, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var lastStep: Int {
        item == nil ? 3 : 2
    }

    private var basicStep: Int {
        item == nil ? 1 : 0
    }

    private var budgetStep: Int {
        item == nil ? 2 : 1
    }

    private var canContinueFromBasic: Bool {
        !trimmedTitle.isEmpty
    }

    private var canAdvanceCurrentStep: Bool {
        if editorStep == basicStep { return canContinueFromBasic }
        if editorStep == budgetStep { return amountValidationMessage == nil }
        return true
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
        !trimmedTitle.isEmpty &&
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

    private func advanceStep() {
        guard editorStep < lastStep else { return }
        guard canAdvanceCurrentStep else { return }

        withAnimation(.easeInOut(duration: 0.2)) {
            editorStep += 1
        }

        if editorStep == basicStep {
            titleFocused = true
        }
    }

    private func save() {
        guard canSave else { return }
        let savedItem: WishItem

        if let item {
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
                savedAmount: parsedSavedAmount
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
        if dismissOnSave {
            dismiss()
        }
        onSave(savedItem)
    }

    private func cancel() {
        if let onCancel {
            onCancel()
        } else {
            dismiss()
        }
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

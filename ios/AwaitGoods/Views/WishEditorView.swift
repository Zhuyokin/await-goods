import SwiftData
import SwiftUI
import UIKit

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
        _note = State(initialValue: item?.note ?? "")
        _markColor = State(initialValue: item?.markColor ?? .none)
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

                    editorSection(appLanguage.text("想买什么"), subtitle: appLanguage.text("先把心动记下来，预算可以慢慢补")) {
                        softTextField(appLanguage.text("名称"), placeholder: appLanguage.text("比如 AirPods、通勤包"), text: $title, icon: "bag")
                            .focused($titleFocused)

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

                        softTextField(appLanguage.text("分类"), placeholder: appLanguage.text("可选"), text: $category, icon: "tag")

                        softTextField(appLanguage.text("链接"), placeholder: appLanguage.text("商品链接，可选"), text: $linkString, icon: "link")
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        categorySuggestions
                    }

                    editorSection(appLanguage.text("存钱计划"), subtitle: appLanguage.text("看见一点点靠近，比倒计时更舒服")) {
                        prioritySelector
                        savingsPreview
                    }

                    editorSection(appLanguage.text("标记与备注")) {
                        markColorSelector

                        TextField(appLanguage.text("为什么想买？现在担心什么？"), text: $note, axis: .vertical)
                            .lineLimit(5...9)
                            .font(.system(size: 16, weight: .medium))
                            .padding(14)
                            .background(HWTheme.fieldBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            .background { HWCreamLeafBackdrop() }
            .navigationTitle(item == nil ? appLanguage.text("新候物") : appLanguage.text("编辑"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(appLanguage.text("取消")) { cancel() }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(appLanguage.text("保存")) { save() }
                        .foregroundStyle(HWTheme.weChatGreen)
                        .disabled(!canSave)
                }
            }
            .onAppear {
                titleFocused = item == nil
            }
    }

    private var editorHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item == nil ? appLanguage.text("先放进清单") : appLanguage.text("调整这件候物"))
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(HWTheme.primaryText)

            Text(appLanguage.text("少填几项也没关系，清单会安静地接住它。"))
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(HWTheme.secondaryText)
        }
        .padding(.top, 8)
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
                            .fill(previewProgress >= 1 ? HWTheme.softBlueGray : HWTheme.freshGreen.opacity(0.72))
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
        !trimmedTitle.isEmpty && amountValidationMessage == nil
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
            item.title = trimmedTitle
            item.price = parsedPrice
            item.savedAmountValue = parsedSavedAmount
            item.linkString = linkString.trimmingCharacters(in: .whitespacesAndNewlines)
            item.category = trimmedCategory
            item.priority = priority
            item.waitUntil = nil
            item.targetDate = nil
            item.notifyEnabled = false
            item.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
            item.markColor = markColor
            item.reconcileSavingsStatus()
            item.updatedAt = Date()
            savedItem = item
        } else {
            let nextIndex = (existingItems.map(\.sortIndex).max() ?? -1) + 1
            let newItem = WishItem(
                title: trimmedTitle,
                price: parsedPrice,
                linkString: linkString.trimmingCharacters(in: .whitespacesAndNewlines),
                note: note.trimmingCharacters(in: .whitespacesAndNewlines),
                category: trimmedCategory,
                priority: priority,
                markColor: markColor,
                sortIndex: nextIndex,
                notifyEnabled: false,
                savedAmount: parsedSavedAmount
            )
            newItem.reconcileSavingsStatus()
            modelContext.insert(newItem)
            savedItem = newItem
        }

        try? modelContext.save()
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
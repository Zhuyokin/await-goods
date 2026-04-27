import SwiftData
import SwiftUI
import UIKit

struct WishEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("defaultWaitDays") private var defaultWaitDays = DefaultWaitPeriod.seven.rawValue
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true

    let item: WishItem?
    let existingItems: [WishItem]
    let onSave: (WishItem) -> Void

    @State private var title: String
    @State private var priceText: String
    @State private var linkString: String
    @State private var category: String
    @State private var priority: WishPriority
    @State private var waitSelection: WaitPeriodSelection
    @State private var customWaitDate: Date
    @State private var hasTargetDate: Bool
    @State private var targetDate: Date
    @State private var notifyEnabled: Bool
    @State private var note: String
    @State private var markColor: MarkColor
    @FocusState private var titleFocused: Bool

    init(item: WishItem?, existingItems: [WishItem], onSave: @escaping (WishItem) -> Void) {
        self.item = item
        self.existingItems = existingItems
        self.onSave = onSave

        _title = State(initialValue: item?.title ?? "")
        _priceText = State(initialValue: item?.price.map { String(format: "%.2f", $0) } ?? "")
        _linkString = State(initialValue: item?.linkString ?? "")
        _category = State(initialValue: item?.category ?? "")
        _priority = State(initialValue: item?.priority ?? .medium)
        _waitSelection = State(initialValue: item?.waitUntil == nil ? .none : .custom)
        _customWaitDate = State(initialValue: item?.waitUntil ?? Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date())
        _hasTargetDate = State(initialValue: item?.targetDate != nil)
        _targetDate = State(initialValue: item?.targetDate ?? Date())
        _notifyEnabled = State(initialValue: item?.notifyEnabled ?? true)
        _note = State(initialValue: item?.note ?? "")
        _markColor = State(initialValue: item?.markColor ?? .none)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    editorHeader

                    editorSection("想买什么", subtitle: "先把心动记下来，细节可以慢慢补") {
                        softTextField("名称", placeholder: "比如 AirPods、通勤包", text: $title, icon: "bag")
                            .focused($titleFocused)

                        HStack(spacing: 8) {
                            softTextField("价格", placeholder: "可选", text: $priceText, icon: "yensign")
                                .keyboardType(.decimalPad)

                            softTextField("分类", placeholder: "可选", text: $category, icon: "tag")
                        }

                        softTextField("链接", placeholder: "商品链接，可选", text: $linkString, icon: "link")
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        categorySuggestions
                    }

                    editorSection("冷静期", subtitle: "给想要一点时间，过了再决定") {
                        prioritySelector
                        waitSelector

                        if waitSelection == .custom {
                            datePickerRow("结束日期", date: $customWaitDate)
                        }

                        toggleRow("目标日期", subtitle: "生日、旅行、搬家前这类节点", isOn: $hasTargetDate, icon: "calendar.badge.clock")

                        if hasTargetDate {
                            datePickerRow("目标日期", date: $targetDate)
                        }

                        toggleRow("提醒", subtitle: "到点提醒你再判断一次", isOn: $notifyEnabled, icon: "bell")
                    }

                    editorSection("标记与备注") {
                        markColorSelector

                        TextField("为什么想买？现在担心什么？", text: $note, axis: .vertical)
                            .lineLimit(5...9)
                            .font(.system(size: 16, weight: .medium))
                            .padding(14)
                            .background(HWTheme.fieldBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            .background { HWCreamLeafBackdrop() }
            .navigationTitle(item == nil ? "新候物" : "编辑")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") { save() }
                        .foregroundStyle(HWTheme.weChatGreen)
                        .disabled(trimmedTitle.isEmpty)
                }
            }
            .onAppear {
                titleFocused = item == nil
                applyDefaultWaitPeriodIfNeeded()
                if item == nil {
                    notifyEnabled = notificationsEnabled
                }
            }
        }
    }

    private var editorHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item == nil ? "先放进清单" : "调整这件候物")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(HWTheme.primaryText)

            Text("少填几项也没关系，关键是先别急着买。")
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
                ForEach(["数码", "衣物", "家居", "书影音", "礼物", "运动"], id: \.self) { suggestion in
                    chipButton(suggestion, isSelected: category == suggestion) {
                        category = suggestion
                    }
                }
            }
        }
    }

    private var prioritySelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            selectorTitle("优先级")

            HStack(spacing: 10) {
                ForEach(WishPriority.allCases) { value in
                    chipButton(value.title, isSelected: priority == value) {
                        priority = value
                    }
                }
            }
        }
    }

    private var waitSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            selectorTitle("等待多久")

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 10)], spacing: 10) {
                ForEach(WaitPeriodSelection.allCases) { value in
                    chipButton(value.title, isSelected: waitSelection == value) {
                        waitSelection = value
                    }
                }
            }
        }
    }

    private var markColorSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            selectorTitle("标记色")

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
                    .accessibilityLabel(color.title)
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
                .foregroundStyle(isSelected ? HWTheme.cardBackground : HWTheme.secondaryText)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: isSelected ? HWTheme.freshGreen.opacity(0.18) : .clear, radius: 7, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    private func datePickerRow(_ title: String, date: Binding<Date>) -> some View {
        DatePicker(title, selection: date, displayedComponents: .date)
            .font(.system(size: 15, weight: .regular))
            .foregroundStyle(HWTheme.primaryText)
            .tint(HWTheme.freshGreen)
            .padding(14)
            .background(HWTheme.fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func toggleRow(_ title: String, subtitle: String, isOn: Binding<Bool>, icon: String) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(HWTheme.freshGreen)
                    .frame(width: 38, height: 38)
                    .background(HWTheme.mint.opacity(0.17))
                    .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))

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
        .padding(14)
        .background(HWTheme.fieldBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func save() {
        let parsedPrice = Double(priceText.replacingOccurrences(of: ",", with: "."))
        let savedItem: WishItem

        if let item {
            item.title = trimmedTitle
            item.price = parsedPrice
            item.linkString = linkString.trimmingCharacters(in: .whitespacesAndNewlines)
            item.category = category.trimmingCharacters(in: .whitespacesAndNewlines)
            item.priority = priority
            item.waitUntil = computedWaitUntil
            item.targetDate = hasTargetDate ? targetDate : nil
            item.notifyEnabled = notifyEnabled
            item.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
            item.markColor = markColor
            item.updatedAt = Date()
            savedItem = item
        } else {
            let nextIndex = (existingItems.map(\.sortIndex).max() ?? -1) + 1
            let newItem = WishItem(
                title: trimmedTitle,
                price: parsedPrice,
                linkString: linkString.trimmingCharacters(in: .whitespacesAndNewlines),
                note: note.trimmingCharacters(in: .whitespacesAndNewlines),
                category: category.trimmingCharacters(in: .whitespacesAndNewlines),
                priority: priority,
                markColor: markColor,
                sortIndex: nextIndex,
                waitUntil: computedWaitUntil,
                targetDate: hasTargetDate ? targetDate : nil,
                notifyEnabled: notifyEnabled
            )
            modelContext.insert(newItem)
            savedItem = newItem
        }

        try? modelContext.save()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        dismiss()
        onSave(savedItem)
    }

    private var computedWaitUntil: Date? {
        switch waitSelection {
        case .none:
            return nil
        case .custom:
            return Calendar.current.startOfDay(for: customWaitDate)
        default:
            return Calendar.current.date(byAdding: .day, value: waitSelection.rawValue, to: Date())
        }
    }

    private func applyDefaultWaitPeriodIfNeeded() {
        guard item == nil, waitSelection == .none else { return }
        guard let defaultPeriod = WaitPeriodSelection(rawValue: defaultWaitDays) else { return }
        waitSelection = defaultPeriod
    }
}

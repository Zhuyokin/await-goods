import SwiftData
import SwiftUI
import UIKit

struct WishListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\WishItem.sortIndex), SortDescriptor(\WishItem.createdAt, order: .reverse)]) private var items: [WishItem]

    @State private var searchText = ""
    @State private var selectedStatus: WishItemStatus?
    @State private var sortMode = SortMode.manual
    @State private var editMode = EditMode.inactive
    @State private var selectedIDs = Set<UUID>()
    @State private var showingEditor = false
    @State private var editingItem: WishItem?
    @State private var selectedDetailItem: WishItem?
    @State private var itemToDelete: WishItem?
    @State private var actionItem: WishItem?
    @State private var showingBulkDeleteConfirmation = false
    @State private var quickAddTitle = ""
    @FocusState private var quickAddFocused: Bool

    private var isEditing: Bool { editMode.isEditing }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerView

                ScrollView {
                    LazyVStack(spacing: 8) {
                        if displayedItems.isEmpty {
                            EmptyStateView()
                                .padding(.top, 48)
                        } else {
                            ForEach(displayedItems) { item in
                                WishRowView(
                                    item: item,
                                    isEditing: isEditing,
                                    isSelected: selectedIDs.contains(item.id),
                                    onCheck: { rowCheckTapped(item) },
                                    onOpen: { open(item) }
                                )
                                .padding(.horizontal, 14)
                                .onLongPressGesture(minimumDuration: 0.35) {
                                    guard !isEditing else { return }
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    actionItem = item
                                }
                            }
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, isEditing ? 82 : 92)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .toolbar(.hidden, for: .navigationBar)
            .background { HWCreamLeafBackdrop() }
            .environment(\.editMode, $editMode)
            .safeAreaInset(edge: .bottom) { bottomBar }
            .sheet(isPresented: $showingEditor) {
                WishEditorView(item: editingItem, existingItems: items) { savedItem in
                    persistChanges()
                    Task { await NotificationScheduler.schedule(for: savedItem) }
                }
            }
            .sheet(item: $selectedDetailItem) { item in
                WishDetailView(item: item) {
                    persistChanges()
                }
            }
            .sheet(item: $actionItem) { item in
                WishActionSheet(
                    item: item,
                    onEdit: { edit(item) },
                    onCopyLink: { UIPasteboard.general.string = item.linkString },
                    onColor: { color in setMarkColor(color, for: item) },
                    onStatus: { status in updateStatus(status, for: item) },
                    onDelete: { itemToDelete = item }
                )
                .presentationDetents([.height(item.linkURL == nil ? 390 : 440)])
                .presentationDragIndicator(.hidden)
                .presentationBackground(HWTheme.pageBackground)
            }
            .alert("删除后不可恢复", isPresented: deleteConfirmationBinding) {
                Button("取消", role: .cancel) { itemToDelete = nil }
                Button("删除", role: .destructive) { deletePendingItem() }
            }
            .alert("删除选中的候物？", isPresented: $showingBulkDeleteConfirmation) {
                Button("取消", role: .cancel) { }
                Button("删除", role: .destructive) { deleteSelectedItems() }
            }
            .onAppear { WidgetSyncService.sync(items: items) }
        }
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("候物")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(HWTheme.primaryText)

                    Text(summaryText)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(HWTheme.secondaryText)
                }

                Spacer()

                HStack(spacing: 6) {
                    Menu {
                        Section("排序") { sortMenuContent }
                        Section("批量") {
                            Button(isEditing ? "完成整理" : "整理清单") { toggleEditing() }
                                .disabled(items.isEmpty && !isEditing)
                        }
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                    .buttonStyle(HeaderIconButtonStyle())

                    Button {
                        editingItem = nil
                        showingEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(FilledHeaderIconButtonStyle())
                }
            }

            searchField
            statusChips
        }
        .padding(.horizontal, 18)
        .padding(.top, 24)
        .padding(.bottom, 14)
        .background(HWTheme.listBackground.opacity(0.78).ignoresSafeArea(edges: .top))
    }

    private var searchField: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(HWTheme.tertiaryText)

            TextField("搜索名称、备注或分类", text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(HWTheme.tertiaryText)
                }
                .buttonStyle(.plain)
            }
        }
        .font(.system(size: 15, weight: .regular))
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(HWTheme.cardBackground.opacity(0.94))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(HWTheme.cardBorder.opacity(0.58), lineWidth: 0.8)
        )
        .shadow(color: HWTheme.softShadow, radius: 2, x: 0, y: 1)
    }

    private var statusChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                statusChip(title: "全部", count: items.count, status: nil)
                ForEach(WishItemStatus.allCases) { status in
                    statusChip(title: status.title, count: items.filter { $0.status == status }.count, status: status)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func statusChip(title: String, count: Int, status: WishItemStatus?) -> some View {
        let isSelected = selectedStatus == status
        return Button {
            selectedStatus = status
        } label: {
            HStack(spacing: 6) {
                Image(systemName: status?.iconName ?? "square.grid.2x2")
                    .font(.system(size: 11, weight: .regular))
                Text(title)
                Text("\(count)")
                    .font(.system(size: 12, weight: .regular).monospacedDigit())
                    .foregroundStyle(isSelected ? HWTheme.cardBackground : HWTheme.tertiaryText)
            }
            .font(.system(size: 14, weight: isSelected ? .medium : .regular))
            .foregroundStyle(isSelected ? HWTheme.cardBackground : HWTheme.secondaryText)
            .padding(.horizontal, 13)
            .padding(.vertical, 8)
            .background(isSelected ? HWTheme.freshGreen.opacity(0.88) : HWTheme.cardBackground.opacity(0.94))
            .foregroundStyle(isSelected ? HWTheme.cardBackground : HWTheme.secondaryText)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? Color.clear : HWTheme.cardBorder.opacity(0.55), lineWidth: 0.8)
            )
            .shadow(color: isSelected ? HWTheme.freshGreen.opacity(0.12) : HWTheme.softShadow.opacity(0.45), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var bottomBar: some View {
        if isEditing {
            VStack(spacing: 9) {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(selectedIDs.isEmpty ? "整理清单" : "已选 \(selectedIDs.count) 件")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(HWTheme.primaryText)

                        Text(selectedIDs.isEmpty ? "轻点左侧图标多选" : "可以批量改为不买、删除或换标记")
                            .font(.system(size: 12))
                            .foregroundStyle(HWTheme.secondaryText)
                    }

                    Spacer()

                    Button("完成") { finishEditing() }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(HWTheme.freshGreen)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(HWTheme.mint.opacity(0.22))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                    HStack(spacing: 8) {
                    batchActionButton("删除", icon: "trash", color: HWTheme.dangerRed) {
                        showingBulkDeleteConfirmation = true
                    }
                    .disabled(selectedIDs.isEmpty)

                    batchActionButton("不买", icon: "xmark", color: HWTheme.tertiaryText) {
                        updateSelectedStatus(.released)
                    }
                    .disabled(selectedIDs.isEmpty)

                    Menu {
                        ForEach(MarkColor.allCases) { color in
                            Button(color.title) { updateSelectedColor(color) }
                        }
                    } label: {
                        HStack(spacing: 7) {
                            Image(systemName: "paintpalette")
                            Text("标记")
                        }
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(selectedIDs.isEmpty ? HWTheme.tertiaryText : HWTheme.softWood)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 9)
                        .background(HWTheme.fieldBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .disabled(selectedIDs.isEmpty)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(HWTheme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(HWTheme.cardBorder.opacity(0.55))
            )
            .shadow(color: HWTheme.softShadow, radius: 8, x: 0, y: 4)
            .padding(.horizontal, 14)
            .padding(.top, 6)
            .padding(.bottom, 6)
            .background(HWTheme.pageBackground.opacity(0.72))
        } else {
            quickAddBar
        }
    }

    private func batchActionButton(_ title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.system(size: 14, weight: .regular))
            .foregroundStyle(selectedIDs.isEmpty ? HWTheme.tertiaryText : color)
            .padding(.horizontal, 11)
            .padding(.vertical, 9)
            .background(HWTheme.fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var quickAddBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(HWTheme.softWood)

            TextField("先记下来，晚点再决定", text: $quickAddTitle)
                .focused($quickAddFocused)
                .submitLabel(.done)
                .onSubmit { quickAdd() }

            Button(action: quickAdd) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(HWTheme.cardBackground)
                    .frame(width: 40, height: 40)
                    .background(trimmedQuickAddTitle.isEmpty ? HWTheme.tertiaryText.opacity(0.72) : HWTheme.freshGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(trimmedQuickAddTitle.isEmpty)
        }
        .font(.system(size: 16, weight: .medium))
        .padding(.leading, 18)
        .padding(.trailing, 8)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(HWTheme.cardBackground.opacity(0.96))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(HWTheme.cardBorder.opacity(0.68), lineWidth: 0.8)
        )
            .shadow(color: HWTheme.softShadow, radius: 3, x: 0, y: 1)
        .padding(.horizontal, 18)
        .padding(.top, 7)
        .padding(.bottom, 7)
        .background(HWTheme.pageBackground.opacity(0.46))
    }

    @ViewBuilder
    private var sortMenuContent: some View {
        ForEach(SortMode.allCases) { mode in
            Button(mode.title) { sortMode = mode }
        }
    }

    private var displayedItems: [WishItem] {
        var result = items

        if let selectedStatus {
            result = result.filter { $0.status == selectedStatus }
        }

        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            result = result.filter { item in
                item.title.localizedCaseInsensitiveContains(query) ||
                item.note.localizedCaseInsensitiveContains(query) ||
                item.category.localizedCaseInsensitiveContains(query)
            }
        }

        switch sortMode {
        case .manual:
            return result.sorted { $0.sortIndex == $1.sortIndex ? $0.createdAt > $1.createdAt : $0.sortIndex < $1.sortIndex }
        case .recent:
            return result.sorted { $0.createdAt > $1.createdAt }
        case .waitEnd:
            return result.sorted { ($0.waitUntil ?? .distantFuture) < ($1.waitUntil ?? .distantFuture) }
        case .priceHigh:
            return result.sorted { ($0.price ?? 0) > ($1.price ?? 0) }
        case .priority:
            return result.sorted { $0.priorityRawValue > $1.priorityRawValue }
        }
    }

    private var summaryText: String {
        let waitingCount = items.filter { $0.status == .waiting }.count
        if items.isEmpty { return "先记下心动，给冲动一点冷静时间" }
        if waitingCount == 0 { return "清单很轻，今天也很克制" }
        return "还有 \(waitingCount) 件想买的东西"
    }

    private var trimmedQuickAddTitle: String {
        quickAddTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var deleteConfirmationBinding: Binding<Bool> {
        Binding(
            get: { itemToDelete != nil },
            set: { if !$0 { itemToDelete = nil } }
        )
    }

    private func rowCheckTapped(_ item: WishItem) {
        if isEditing {
            if selectedIDs.contains(item.id) {
                selectedIDs.remove(item.id)
            } else {
                selectedIDs.insert(item.id)
            }
            return
        }

        switch item.status {
        case .waiting:
            updateStatus(.bought, for: item)
        case .bought, .released, .paused:
            updateStatus(.waiting, for: item)
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func open(_ item: WishItem) {
        if isEditing {
            rowCheckTapped(item)
        } else {
            selectedDetailItem = item
        }
    }

    private func edit(_ item: WishItem) {
        editingItem = item
        showingEditor = true
    }

    private func updateStatus(_ status: WishItemStatus, for item: WishItem) {
        item.status = status
        persistChanges()

        Task {
            if status == .waiting {
                await NotificationScheduler.schedule(for: item)
            } else {
                await NotificationScheduler.cancel(for: item)
            }
        }
    }

    private func setMarkColor(_ color: MarkColor, for item: WishItem) {
        item.markColor = color
        persistChanges()
    }

    private func updateSelectedStatus(_ status: WishItemStatus) {
        let selectedItems = items.filter { selectedIDs.contains($0.id) }
        selectedItems.forEach { $0.status = status }
        persistChanges()

        Task {
            for item in selectedItems {
                if status == .waiting {
                    await NotificationScheduler.schedule(for: item)
                } else {
                    await NotificationScheduler.cancel(for: item)
                }
            }
        }
    }

    private func updateSelectedColor(_ color: MarkColor) {
        items.filter { selectedIDs.contains($0.id) }.forEach { $0.markColor = color }
        persistChanges()
    }

    private func deletePendingItem() {
        guard let itemToDelete else { return }
        Task { await NotificationScheduler.cancel(for: itemToDelete) }
        modelContext.delete(itemToDelete)
        self.itemToDelete = nil
        persistChanges()
    }

    private func deleteSelectedItems() {
        let selectedItems = items.filter { selectedIDs.contains($0.id) }
        selectedItems.forEach { item in
            Task { await NotificationScheduler.cancel(for: item) }
            modelContext.delete(item)
        }
        selectedIDs.removeAll()
        persistChanges()
    }

    private func moveItems(from source: IndexSet, to destination: Int) {
        var reordered = displayedItems
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, item) in reordered.enumerated() {
            item.sortIndex = index
            item.updatedAt = Date()
        }
        persistChanges()
    }

    private func quickAdd() {
        guard !trimmedQuickAddTitle.isEmpty else { return }
        let nextIndex = (items.map(\.sortIndex).max() ?? -1) + 1
        let defaultWaitDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())
        let newItem = WishItem(
            title: trimmedQuickAddTitle,
            price: nil,
            linkString: "",
            note: "",
            category: "",
            priority: .medium,
            markColor: .none,
            sortIndex: nextIndex,
            waitUntil: defaultWaitDate,
            targetDate: nil,
            notifyEnabled: true
        )
        modelContext.insert(newItem)
        quickAddTitle = ""
        quickAddFocused = false
        persistChanges()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        Task { await NotificationScheduler.schedule(for: newItem) }
    }

    private func toggleEditing() {
        if isEditing {
            finishEditing()
        } else {
            editMode = .active
        }
    }

    private func finishEditing() {
        selectedIDs.removeAll()
        editMode = .inactive
    }

    private func persistChanges() {
        try? modelContext.save()
        WidgetSyncService.sync(items: items)
    }
}

private struct HeaderIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(configuration.isPressed ? HWTheme.freshGreen : HWTheme.primaryText)
            .frame(width: 44, height: 44)
            .background(HWTheme.cardBackground.opacity(configuration.isPressed ? 0.78 : 0.94))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(HWTheme.cardBorder.opacity(0.58), lineWidth: 0.8)
            )
            .shadow(color: HWTheme.softShadow, radius: 2, x: 0, y: 1)
    }
}

private struct FilledHeaderIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 20, weight: .bold))
            .foregroundStyle(HWTheme.cardBackground)
            .frame(width: 46, height: 46)
            .background(configuration.isPressed ? HWTheme.apricot : HWTheme.freshGreen)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: HWTheme.freshGreen.opacity(0.14), radius: 2, x: 0, y: 1)
    }
}

private struct WishActionSheet: View {
    @Environment(\.dismiss) private var dismiss

    let item: WishItem
    let onEdit: () -> Void
    let onCopyLink: () -> Void
    let onColor: (MarkColor) -> Void
    let onStatus: (WishItemStatus) -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Capsule()
                .fill(HWTheme.separator)
                .padding(.horizontal, 148)
                .padding(.top, 10)

            WishRowView(item: item, isEditing: false, isSelected: false, onCheck: {}, onOpen: {})
                .allowsHitTesting(false)

            VStack(spacing: 10) {
                actionRow("编辑", icon: "pencil", color: HWTheme.primaryText) { onEdit() }

                if item.linkURL != nil {
                    actionRow("复制链接", icon: "link", color: HWTheme.linkBlue) { onCopyLink() }
                }

                HStack(spacing: 10) {
                    Text("换个标记")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(HWTheme.secondaryText)

                    Spacer()

                    ForEach(MarkColor.allCases) { color in
                        Button {
                            run { onColor(color) }
                        } label: {
                            Image(systemName: color == .none ? "circle" : "circle.fill")
                                .font(.system(size: 22, weight: .regular))
                                .foregroundStyle(color == .none ? HWTheme.tertiaryText : HWTheme.markColor(color))
                                .overlay {
                                    if item.markColor == color {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 9, weight: .medium))
                                            .foregroundStyle(HWTheme.primaryText)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(color.title)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(HWTheme.cardBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(HWTheme.cardBorder.opacity(0.55))
                )

                HStack(spacing: 8) {
                    compactAction("已买", icon: WishItemStatus.bought.iconName, color: HWTheme.sky) { onStatus(.bought) }
                    compactAction("不买", icon: WishItemStatus.released.iconName, color: HWTheme.tertiaryText) { onStatus(.released) }
                    compactAction("再想想", icon: WishItemStatus.paused.iconName, color: HWTheme.butter) { onStatus(.paused) }
                }

                actionRow("删除", icon: "trash", color: HWTheme.dangerRed) { onDelete() }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .background(HWTheme.pageBackground)
    }

    private func actionRow(_ title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button {
            run(action)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(color)

                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(color)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(HWTheme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(HWTheme.cardBorder.opacity(0.55))
            )
        }
        .buttonStyle(.plain)
    }

    private func compactAction(_ title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button {
            run(action)
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .regular))
                Text(title)
                    .font(.system(size: 13, weight: .regular))
            }
            .foregroundStyle(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(HWTheme.fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func run(_ action: @escaping () -> Void) {
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            action()
        }
    }
}

private enum SortMode: String, CaseIterable, Identifiable {
    case manual
    case recent
    case waitEnd
    case priceHigh
    case priority

    var id: String { rawValue }

    var title: String {
        switch self {
        case .manual: return "手动排序"
        case .recent: return "最近添加"
        case .waitEnd: return "等待结束"
        case .priceHigh: return "价格高低"
        case .priority: return "优先级"
        }
    }
}
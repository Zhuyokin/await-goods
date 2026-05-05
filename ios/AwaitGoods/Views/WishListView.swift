import SwiftData
import SwiftUI
import UIKit
import UniformTypeIdentifiers

private enum QuickAddField: Hashable {
    case title
    case price
    case saved
    case category
}

struct WishListView: View {
    @Environment(\.appLanguage) private var appLanguage
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\WishItem.sortIndex), SortDescriptor(\WishItem.createdAt, order: .reverse)]) private var items: [WishItem]

    @State private var searchText = ""
    @State private var isSearchPresented = false
    @State private var selectedStatus: WishItemStatus? = .waiting
    @State private var sortMode = SortMode.manual
    @State private var editMode = EditMode.inactive
    @State private var selectedIDs = Set<UUID>()
    @State private var showingEditor = false
    @State private var editingItem: WishItem?
    @State private var selectedDetailItem: WishItem?
    @State private var itemToDelete: WishItem?
    @State private var actionItem: WishItem?
    @State private var showingBulkDeleteConfirmation = false
    @State private var showingQuickAddSheet = false
    @State private var showingTrash = false
    @State private var linkCopiedToastVisible = false
    @State private var linkCopiedToastToken = UUID()
    @State private var changeEffect: WishChangeEffect?
    @State private var changeEffectToken = UUID()
    @State private var quickAddTitle = ""
    @State private var quickAddPriceText = ""
    @State private var quickAddSavedText = ""
    @State private var quickAddCategory = ""
    @State private var draggedItem: WishItem?
    @State private var dragOrderedIDs: [UUID] = []
    @FocusState private var searchFieldFocused: Bool
    @FocusState private var quickAddField: QuickAddField?

    private var isEditing: Bool { editMode.isEditing }
    private var activeItems: [WishItem] { items.filter { !$0.isTrashed } }
    private var trashedItems: [WishItem] { items.filter(\.isTrashed) }

    var body: some View {
        NavigationStack {
            rootContent
        }
    }

    private var rootContent: some View {
        VStack(spacing: 0) {
            headerView
            itemScrollView
        }
        .toolbar(.hidden, for: .navigationBar)
        .background { HWCreamLeafBackdrop() }
        .environment(\.editMode, $editMode)
        .safeAreaInset(edge: .bottom) { bottomBar }
        .sheet(isPresented: $showingQuickAddSheet, onDismiss: resetQuickAddDraft) { quickAddSheet }
        .sheet(isPresented: $showingEditor) { editorSheet }
        .sheet(item: $selectedDetailItem) { item in detailSheet(for: item) }
        .sheet(item: $actionItem) { item in actionSheet(for: item) }
        .sheet(isPresented: $showingTrash) { trashSheet }
        .overlay(alignment: .bottom) { floatingAccessoryButtons }
        .overlay(alignment: .bottom) { copyLinkToast }
        .overlay { changeEffectOverlay }
        .alert(appLanguage.text("移入回收站？"), isPresented: deleteConfirmationBinding) {
            Button(appLanguage.text("取消"), role: .cancel) { itemToDelete = nil }
            Button(appLanguage.text("移入回收站"), role: .destructive) { movePendingItemToTrash() }
        } message: {
            Text(appLanguage.text("删除会先放进回收站"))
        }
        .alert(appLanguage.text("移入回收站？"), isPresented: $showingBulkDeleteConfirmation) {
            Button(appLanguage.text("取消"), role: .cancel) { }
            Button(appLanguage.text("移入回收站"), role: .destructive) { moveSelectedItemsToTrash() }
        } message: {
            Text(appLanguage.text("删除会先放进回收站"))
        }
        .onAppear {
            NotificationScheduler.cancelAllWishNotifications()
            WidgetSyncService.sync(items: activeItems)
        }
    }

    private var itemScrollView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                if displayedItems.isEmpty {
                    EmptyStateView()
                        .padding(.top, 48)
                } else {
                    ForEach(displayedItems) { item in
                        rowView(for: item)
                    }
                }
            }
            .padding(.top, 8)
            .padding(.bottom, isEditing ? 82 : 118)
            .animation(.spring(response: 0.34, dampingFraction: 0.82), value: displayedItemIDs)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func rowView(for item: WishItem) -> some View {
        WishRowView(
            item: item,
            isEditing: isEditing,
            isSelected: selectedIDs.contains(item.id),
            onCheck: { rowCheckTapped(item) },
            onOpen: { open(item) },
            onMore: { actionItem = item }
        )
        .padding(.horizontal, 14)
        .transition(.asymmetric(insertion: .scale(scale: 0.96).combined(with: .opacity), removal: .move(edge: .trailing).combined(with: .opacity)))
        .onDrag {
            sortMode = .manual
            draggedItem = item
            dragOrderedIDs = manuallySorted(activeItems).map(\.id)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            return NSItemProvider(object: item.id.uuidString as NSString)
        }
        .onDrop(
            of: [UTType.text],
            delegate: WishDropDelegate(
                targetItem: item,
                draggedItem: $draggedItem,
                orderedIDs: $dragOrderedIDs,
                commitMove: commitDragOrder
            )
        )
    }

    private var editorSheet: some View {
        WishEditorView(item: editingItem, existingItems: activeItems) { _ in
            persistChanges()
        }
    }

    private func detailSheet(for item: WishItem) -> some View {
        WishDetailView(item: item) {
            persistChanges()
        }
    }

    private func actionSheet(for item: WishItem) -> some View {
        WishActionSheet(
            item: item,
            onEdit: { edit(item) },
            onCopyLink: { copyLink(for: item) },
            onColor: { color in setMarkColor(color, for: item) },
            onStatus: { status in updateStatus(status, for: item) },
            onDelete: { itemToDelete = item }
        )
        .presentationDetents([.height(item.linkURL == nil ? 350 : 400)])
        .presentationDragIndicator(.hidden)
        .presentationBackground(HWTheme.pageBackground)
    }

    private var trashSheet: some View {
        TrashBinView(
            items: trashedItems,
            onRestore: restoreFromTrash,
            onDeleteForever: permanentlyDelete,
            onEmptyTrash: emptyTrash
        )
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                HStack(spacing: 10) {
                    AppLogoMark()

                    VStack(alignment: .leading, spacing: 5) {
                        Text(appLanguage.text("候物"))
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundStyle(HWTheme.primaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                            .allowsTightening(true)

                        Text(summaryText)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(HWTheme.secondaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.84)
                            .truncationMode(.tail)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)

                HStack(spacing: 8) {
                    Button(action: toggleSearch) {
                        Image(systemName: isSearchPresented ? "xmark" : "magnifyingglass")
                    }
                    .buttonStyle(HeaderIconButtonStyle())

                    Menu {
                        Section(appLanguage.text("排序")) { sortMenuContent }
                        Section(appLanguage.text("批量")) {
                            Button(isEditing ? appLanguage.text("完成整理") : appLanguage.text("整理清单")) { toggleEditing() }
                                .disabled(activeItems.isEmpty && !isEditing)
                        }
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                    .buttonStyle(HeaderIconButtonStyle())
                }
            }

            if isSearchPresented {
                searchField
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            statusChips
        }
        .padding(.horizontal, 18)
        .padding(.top, 24)
        .padding(.bottom, 14)
        .background(HWTheme.listBackground.opacity(0.78).ignoresSafeArea(edges: .top))
        .animation(.easeInOut(duration: 0.18), value: isSearchPresented)
    }

    private var searchField: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(HWTheme.tertiaryText)

            TextField(appLanguage.text("搜索名称、备注或分类"), text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($searchFieldFocused)
                .submitLabel(.search)

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
                ForEach(WishItemStatus.allCases) { status in
                    statusChip(title: appLanguage.text(status.title), count: activeItems.filter { $0.status == status }.count, status: status)
                }
                statusChip(title: appLanguage.text("全部"), count: activeItems.count, status: nil)
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
    private var floatingAccessoryButtons: some View {
        if !isEditing {
            HStack(alignment: .bottom) {
                floatingTrashButton

                Spacer(minLength: 0)

                floatingAddButton
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 18)
            .transition(.scale(scale: 0.82).combined(with: .opacity))
        }
    }

    private var floatingTrashButton: some View {
        Button {
            showingTrash = true
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "trash")

                if !trashedItems.isEmpty {
                    Text("\(min(trashedItems.count, 99))")
                        .font(.system(size: 10, weight: .semibold).monospacedDigit())
                        .foregroundStyle(HWTheme.cardBackground)
                        .frame(minWidth: 17, minHeight: 17)
                        .background(HWTheme.dangerRed)
                        .clipShape(Capsule())
                        .offset(x: 8, y: -8)
                }
            }
        }
        .buttonStyle(FloatingTrashButtonStyle())
        .accessibilityLabel(appLanguage.text("回收站"))
    }

    private var floatingAddButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                selectedStatus = .waiting
                showingQuickAddSheet = true
            }
        } label: {
            Image(systemName: "plus")
        }
        .buttonStyle(FloatingAddButtonStyle())
        .accessibilityLabel(appLanguage.text("新增候物"))
    }

    @ViewBuilder
    private var bottomBar: some View {
        if isEditing {
            VStack(spacing: 9) {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(selectedIDs.isEmpty ? appLanguage.text("整理清单") : String(format: appLanguage.text("已选 %d 件"), selectedIDs.count))
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(HWTheme.primaryText)

                        Text(selectedIDs.isEmpty ? appLanguage.text("轻点左侧图标多选") : appLanguage.text("可以批量放下、移入回收站或换标记"))
                            .font(.system(size: 12))
                            .foregroundStyle(HWTheme.secondaryText)
                    }

                    Spacer()

                    Button(appLanguage.text("完成")) { finishEditing() }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(HWTheme.freshGreen)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(HWTheme.mint.opacity(0.22))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                HStack(spacing: 8) {
                    batchActionButton(appLanguage.text("删除"), icon: "trash", color: HWTheme.dangerRed) {
                        showingBulkDeleteConfirmation = true
                    }
                    .disabled(selectedIDs.isEmpty)

                    batchActionButton(appLanguage.text(WishItemStatus.released.title), icon: "xmark", color: HWTheme.tertiaryText) {
                        updateSelectedStatus(.released)
                    }
                    .disabled(selectedIDs.isEmpty)

                    Menu {
                        ForEach(MarkColor.allCases) { color in
                            Button(appLanguage.text(color.title)) { updateSelectedColor(color) }
                        }
                    } label: {
                        HStack(spacing: 7) {
                            Image(systemName: "paintpalette")
                            Text(appLanguage.text("标记"))
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

    private var quickAddSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(appLanguage.text("先记下一个心愿"))
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(HWTheme.primaryText)

                        Text(appLanguage.text("少填几项也没关系，清单会安静地接住它。"))
                            .font(.system(size: 13))
                            .foregroundStyle(HWTheme.secondaryText)
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundStyle(HWTheme.softWood)

                        TextField(appLanguage.text("先记下一个心愿"), text: $quickAddTitle)
                            .font(.system(size: 16, weight: .medium))
                            .focused($quickAddField, equals: .title)
                            .submitLabel(.next)
                            .onSubmit { quickAddField = .price }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 13)
                    .background(HWTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(HWTheme.cardBorder.opacity(0.58), lineWidth: 0.8)
                    )

                    HStack(spacing: 8) {
                        compactQuickField(appLanguage.text("价格"), text: $quickAddPriceText, icon: "dollarsign", field: .price)
                            .keyboardType(.decimalPad)
                            .submitLabel(.next)
                            .onSubmit { quickAddField = .saved }

                        compactQuickField(appLanguage.text("已存"), text: $quickAddSavedText, icon: "banknote", field: .saved)
                            .keyboardType(.decimalPad)
                            .submitLabel(.next)
                            .onSubmit { quickAddField = .category }

                        compactQuickField(appLanguage.text("标签"), text: $quickAddCategory, icon: "tag", field: .category)
                            .submitLabel(.done)
                    }

                    quickCategorySuggestions

                    if let quickAddValidationMessage {
                        Text(quickAddValidationMessage)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(HWTheme.dangerRed)
                    }

                    Button(action: quickAdd) {
                        Text(appLanguage.text("先放进清单"))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(HWTheme.cardBackground)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(canQuickAdd ? HWTheme.freshGreen : HWTheme.tertiaryText.opacity(0.72))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .disabled(!canQuickAdd)
                    .buttonStyle(.plain)
                }
                .padding(18)
            }
            .background(HWTheme.pageBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(appLanguage.text("取消")) { closeQuickAddSheet() }
                        .foregroundStyle(HWTheme.secondaryText)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(HWTheme.pageBackground)
        .onAppear {
            quickAddField = .title
        }
    }

    private func compactQuickField(_ title: String, text: Binding<String>, icon: String, field: QuickAddField) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(HWTheme.freshGreen)

            TextField(title, text: text)
                .font(.system(size: 13, weight: .medium))
                .focused($quickAddField, equals: field)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(HWTheme.fieldBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var quickCategorySuggestions: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                ForEach(WishCategoryCatalog.suggestions(from: activeItems, including: quickAddCategory), id: \.self) { category in
                    Button {
                        quickAddCategory = category
                    } label: {
                        Text(appLanguage.text(category))
                            .font(.system(size: 12, weight: trimmedQuickAddCategory == category ? .medium : .regular))
                            .foregroundStyle(trimmedQuickAddCategory == category ? HWTheme.cardBackground : HWTheme.secondaryText)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 6)
                            .background(trimmedQuickAddCategory == category ? HWTheme.freshGreen.opacity(0.82) : HWTheme.fieldBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private var sortMenuContent: some View {
        ForEach(SortMode.allCases) { mode in
            Button(appLanguage.text(mode.title)) { sortMode = mode }
        }
    }

    private var displayedItems: [WishItem] {
        var result = activeItems

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
            return manuallySorted(result)
        case .recent:
            return result.sorted { $0.createdAt > $1.createdAt }
        case .savings:
            return result.sorted { $0.savingsProgress == $1.savingsProgress ? ($0.price ?? 0) > ($1.price ?? 0) : $0.savingsProgress > $1.savingsProgress }
        case .priceHigh:
            return result.sorted { ($0.price ?? 0) > ($1.price ?? 0) }
        case .priority:
            return result.sorted { $0.priorityRawValue > $1.priorityRawValue }
        }
    }

    private var displayedItemIDs: [UUID] {
        displayedItems.map(\.id)
    }

    private var summaryText: String {
        let waitingCount = activeItems.filter { $0.status == .waiting }.count
        if activeItems.isEmpty { return appLanguage.text("先记下心动，给预算一点空间") }
        if waitingCount == 0 { return appLanguage.text("清单很轻，今天也很清爽") }
        return String(format: appLanguage.text("还有 %d 件想买的东西"), waitingCount)
    }

    private var trimmedQuickAddTitle: String {
        quickAddTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedQuickAddCategory: String {
        quickAddCategory.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @ViewBuilder
    private var copyLinkToast: some View {
        if linkCopiedToastVisible {
            Label(appLanguage.text("已复制"), systemImage: "checkmark.circle.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(HWTheme.cardBackground)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(HWTheme.primaryText.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: HWTheme.softShadow, radius: 8, x: 0, y: 4)
                .padding(.bottom, isEditing ? 108 : 18)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private var quickAddParsedPrice: Double? {
        normalizedAmount(from: quickAddPriceText)
    }

    private var quickAddParsedSavedAmount: Double {
        normalizedAmount(from: quickAddSavedText) ?? 0
    }

    private var quickAddValidationMessage: String? {
        let hasPrice = !quickAddPriceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasSaved = !quickAddSavedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        if hasPrice && quickAddParsedPrice == nil { return appLanguage.text("价格需大于 0") }
        if hasSaved && normalizedAmount(from: quickAddSavedText) == nil { return appLanguage.text("已存需大于 0") }
        if let quickAddParsedPrice, quickAddParsedSavedAmount > quickAddParsedPrice { return appLanguage.text("已存不能超过价格") }
        return nil
    }

    private var canQuickAdd: Bool {
        !trimmedQuickAddTitle.isEmpty && quickAddValidationMessage == nil
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
        case .bought, .released:
            updateStatus(.waiting, for: item)
        }
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
        guard item.status != status else { return }
        showChangeEffect(.status(status))
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                item.status = status
            }
            persistChanges()
        }
    }

    private func commitStatus(_ status: WishItemStatus, for itemsToUpdate: [WishItem]) {
        let changingItems = itemsToUpdate.filter { $0.status != status && !$0.isTrashed }
        guard !changingItems.isEmpty else { return }
        showChangeEffect(.status(status))
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                changingItems.forEach { $0.status = status }
            }
            persistChanges()
        }
    }

    private func setMarkColor(_ color: MarkColor, for item: WishItem) {
        item.markColor = color
        persistChanges()
    }

    private func copyLink(for item: WishItem) {
        let linkString = item.linkString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !linkString.isEmpty else { return }
        UIPasteboard.general.string = linkString
        showCopyLinkToast()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func showCopyLinkToast() {
        let toastToken = UUID()
        linkCopiedToastToken = toastToken

        withAnimation(.easeInOut(duration: 0.18)) {
            linkCopiedToastVisible = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            guard linkCopiedToastToken == toastToken else { return }
            withAnimation(.easeInOut(duration: 0.18)) {
                linkCopiedToastVisible = false
            }
        }
    }

    private func updateSelectedStatus(_ status: WishItemStatus) {
        let selectedItems = activeItems.filter { selectedIDs.contains($0.id) }
        commitStatus(status, for: selectedItems)
        selectedIDs.removeAll()
    }

    private func updateSelectedColor(_ color: MarkColor) {
        activeItems.filter { selectedIDs.contains($0.id) }.forEach { $0.markColor = color }
        persistChanges()
    }

    private func movePendingItemToTrash() {
        guard let itemToDelete else { return }
        moveToTrash([itemToDelete])
        self.itemToDelete = nil
    }

    private func moveSelectedItemsToTrash() {
        let selectedItems = activeItems.filter { selectedIDs.contains($0.id) }
        moveToTrash(selectedItems)
        selectedIDs.removeAll()
    }

    private func moveToTrash(_ itemsToTrash: [WishItem]) {
        guard !itemsToTrash.isEmpty else { return }
        showChangeEffect(.trashed)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                itemsToTrash.forEach { item in
                    Task { await NotificationScheduler.cancel(for: item) }
                    item.moveToTrash()
                }
            }
            persistChanges()
        }
    }

    private func restoreFromTrash(_ item: WishItem) {
        showChangeEffect(.restored)
        withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
            item.restoreFromTrash()
        }
        persistChanges()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func permanentlyDelete(_ item: WishItem) {
        withAnimation(.easeInOut(duration: 0.18)) {
            modelContext.delete(item)
        }
        persistChanges()
    }

    private func emptyTrash() {
        let itemsToDelete = trashedItems
        guard !itemsToDelete.isEmpty else { return }
        withAnimation(.easeInOut(duration: 0.18)) {
            itemsToDelete.forEach { modelContext.delete($0) }
        }
        persistChanges()
    }

    private func showChangeEffect(_ kind: WishChangeEffectKind) {
        let token = UUID()
        changeEffectToken = token

        withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
            changeEffect = WishChangeEffect(kind: kind)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.92) {
            guard changeEffectToken == token else { return }
            withAnimation(.easeInOut(duration: 0.18)) {
                changeEffect = nil
            }
        }
    }

    @ViewBuilder
    private var changeEffectOverlay: some View {
        if let changeEffect {
            WishChangeEffectView(effect: changeEffect)
                .padding(.bottom, isEditing ? 68 : 0)
                .transition(.scale(scale: 0.82).combined(with: .opacity))
        }
    }

    private func manuallySorted(_ sourceItems: [WishItem]) -> [WishItem] {
        if dragOrderedIDs.isEmpty {
            return sourceItems.sorted { $0.sortIndex == $1.sortIndex ? $0.createdAt > $1.createdAt : $0.sortIndex < $1.sortIndex }
        }

        let sourceByID = Dictionary(uniqueKeysWithValues: sourceItems.map { ($0.id, $0) })
        let orderedItems = dragOrderedIDs.compactMap { sourceByID[$0] }
        let orderedIDSet = Set(dragOrderedIDs)
        let remainingItems = sourceItems
            .filter { !orderedIDSet.contains($0.id) }
            .sorted { $0.sortIndex == $1.sortIndex ? $0.createdAt > $1.createdAt : $0.sortIndex < $1.sortIndex }
        return orderedItems + remainingItems
    }

    private func commitDragOrder(_ orderedIDs: [UUID]) {
        guard !orderedIDs.isEmpty else { return }
        let itemByID = Dictionary(uniqueKeysWithValues: activeItems.map { ($0.id, $0) })
        for (index, id) in orderedIDs.enumerated() {
            guard let item = itemByID[id] else { continue }
            item.sortIndex = index
            item.updatedAt = Date()
        }
        persistChanges()
    }

    private func quickAdd() {
        guard canQuickAdd else { return }
        let nextIndex = (activeItems.map(\.sortIndex).max() ?? -1) + 1
        let newItem = WishItem(
            title: trimmedQuickAddTitle,
            price: quickAddParsedPrice,
            linkString: "",
            note: "",
            category: trimmedQuickAddCategory,
            priority: .medium,
            markColor: .none,
            sortIndex: nextIndex,
            notifyEnabled: false,
            savedAmount: quickAddParsedSavedAmount
        )
        newItem.reconcileSavingsStatus()
        modelContext.insert(newItem)
        selectedStatus = .waiting
        persistChanges()
        closeQuickAddSheet()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func closeQuickAddSheet() {
        resetQuickAddDraft()
        showingQuickAddSheet = false
    }

    private func resetQuickAddDraft() {
        quickAddTitle = ""
        quickAddPriceText = ""
        quickAddSavedText = ""
        quickAddCategory = ""
        quickAddField = nil
    }

    private func normalizedAmount(from text: String) -> Double? {
        let normalized = text
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Double(normalized), value > 0 else { return nil }
        return value
    }

    private func toggleSearch() {
        withAnimation(.easeInOut(duration: 0.18)) {
            if isSearchPresented {
                searchText = ""
                isSearchPresented = false
                searchFieldFocused = false
            } else {
                isSearchPresented = true
            }
        }

        if isSearchPresented {
            DispatchQueue.main.async {
                searchFieldFocused = true
            }
        }
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
        WidgetSyncService.sync(items: activeItems)
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

private struct FloatingAddButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 20, weight: .bold))
            .foregroundStyle(HWTheme.cardBackground)
            .frame(width: 58, height: 58)
            .background(configuration.isPressed ? HWTheme.apricot : HWTheme.freshGreen)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(HWTheme.cardBackground.opacity(0.88), lineWidth: 2)
            )
            .shadow(color: HWTheme.freshGreen.opacity(configuration.isPressed ? 0.10 : 0.24), radius: 10, x: 0, y: 5)
    }
}

private struct FloatingTrashButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(configuration.isPressed ? HWTheme.cardBackground : HWTheme.dangerRed)
            .frame(width: 52, height: 52)
            .background(configuration.isPressed ? HWTheme.dangerRed : HWTheme.cardBackground.opacity(0.96))
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(HWTheme.cardBorder.opacity(0.62), lineWidth: 0.8)
            )
            .shadow(color: HWTheme.softShadow, radius: 9, x: 0, y: 5)
    }
}

private struct TrashBinView: View {
    @Environment(\.appLanguage) private var appLanguage
    @Environment(\.dismiss) private var dismiss

    let items: [WishItem]
    let onRestore: (WishItem) -> Void
    let onDeleteForever: (WishItem) -> Void
    let onEmptyTrash: () -> Void

    @State private var itemToDeleteForever: WishItem?
    @State private var showingEmptyConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 10) {
                    if sortedItems.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "trash")
                                .font(.system(size: 32, weight: .ultraLight))
                                .foregroundStyle(HWTheme.tertiaryText)
                                .padding(.bottom, 4)

                            Text(appLanguage.text("回收站为空"))
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(HWTheme.primaryText)

                            Text(appLanguage.text("暂无已删除候物"))
                                .font(.system(size: 13))
                                .foregroundStyle(HWTheme.tertiaryText)
                        }
                        .padding(22)
                        .frame(maxWidth: .infinity)
                        .softCard()
                        .padding(.horizontal, 14)
                        .padding(.top, 42)
                    } else {
                        ForEach(sortedItems) { item in
                            trashRow(for: item)
                                .padding(.horizontal, 14)
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                        }
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 24)
                .animation(.spring(response: 0.34, dampingFraction: 0.82), value: sortedItems.map(\.id))
            }
            .background(HWTheme.pageBackground.ignoresSafeArea())
            .navigationTitle(appLanguage.text("回收站"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(appLanguage.text("完成")) { dismiss() }
                        .foregroundStyle(HWTheme.freshGreen)
                }

                if !sortedItems.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(appLanguage.text("清空"), role: .destructive) {
                            showingEmptyConfirmation = true
                        }
                        .foregroundStyle(HWTheme.dangerRed)
                    }
                }
            }
            .alert(appLanguage.text("确认彻底删除？"), isPresented: deleteForeverBinding) {
                Button(appLanguage.text("取消"), role: .cancel) { itemToDeleteForever = nil }
                Button(appLanguage.text("彻底删除"), role: .destructive) {
                    guard let itemToDeleteForever else { return }
                    onDeleteForever(itemToDeleteForever)
                    self.itemToDeleteForever = nil
                }
            } message: {
                Text(appLanguage.text("这些候物将无法恢复"))
            }
            .alert(appLanguage.text("清空回收站？"), isPresented: $showingEmptyConfirmation) {
                Button(appLanguage.text("取消"), role: .cancel) { }
                Button(appLanguage.text("清空"), role: .destructive) { onEmptyTrash() }
            } message: {
                Text(appLanguage.text("这些候物将无法恢复"))
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(HWTheme.pageBackground)
    }

    private var sortedItems: [WishItem] {
        items.sorted { lhs, rhs in
            switch (lhs.trashedAt, rhs.trashedAt) {
            case let (lhsDate?, rhsDate?): return lhsDate > rhsDate
            case (_?, nil): return true
            case (nil, _?): return false
            case (nil, nil): return lhs.updatedAt > rhs.updatedAt
            }
        }
    }

    private var deleteForeverBinding: Binding<Bool> {
        Binding(
            get: { itemToDeleteForever != nil },
            set: { if !$0 { itemToDeleteForever = nil } }
        )
    }

    private func trashRow(for item: WishItem) -> some View {
        VStack(spacing: 10) {
            WishRowView(item: item, isEditing: false, isSelected: false, onCheck: {}, onOpen: {}, onMore: nil)
                .allowsHitTesting(false)

            HStack(spacing: 8) {
                trashActionButton(appLanguage.text("恢复"), icon: "arrow.uturn.left", color: HWTheme.freshGreen) {
                    onRestore(item)
                }

                trashActionButton(appLanguage.text("彻底删除"), icon: "trash.slash", color: HWTheme.dangerRed) {
                    itemToDeleteForever = item
                }
            }
        }
        .padding(10)
        .background(HWTheme.cardBackground.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(HWTheme.cardBorder.opacity(0.58), lineWidth: 0.8)
        )
    }

    private func trashActionButton(_ title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(HWTheme.fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct WishActionSheet: View {
    @Environment(\.appLanguage) private var appLanguage
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

            WishRowView(item: item, isEditing: false, isSelected: false, onCheck: {}, onOpen: {}, onMore: nil)
                .allowsHitTesting(false)

            VStack(spacing: 10) {
                actionRow(appLanguage.text("编辑"), icon: "pencil", color: HWTheme.primaryText) { onEdit() }

                if item.linkURL != nil {
                    actionRow(appLanguage.text("复制链接"), icon: "link", color: HWTheme.linkBlue) { onCopyLink() }
                }

                HStack(spacing: 10) {
                    Text(appLanguage.text("换个标记"))
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
                        .accessibilityLabel(appLanguage.text(color.title))
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
                    compactAction(appLanguage.text(WishItemStatus.waiting.title), icon: WishItemStatus.waiting.iconName, color: HWTheme.freshGreen) { onStatus(.waiting) }
                    compactAction(appLanguage.text(WishItemStatus.bought.title), icon: WishItemStatus.bought.iconName, color: HWTheme.sky) { onStatus(.bought) }
                    compactAction(appLanguage.text(WishItemStatus.released.title), icon: WishItemStatus.released.iconName, color: HWTheme.tertiaryText) { onStatus(.released) }
                }

                actionRow(appLanguage.text("移入回收站"), icon: "trash", color: HWTheme.dangerRed) { onDelete() }
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
    case savings
    case priceHigh
    case priority

    var id: String { rawValue }

    var title: String {
        switch self {
        case .manual: return "手动排序"
        case .recent: return "最近添加"
        case .savings: return "存钱进度"
        case .priceHigh: return "价格高低"
        case .priority: return "优先级"
        }
    }
}

private struct WishDropDelegate: DropDelegate {
    let targetItem: WishItem
    @Binding var draggedItem: WishItem?
    @Binding var orderedIDs: [UUID]
    let commitMove: ([UUID]) -> Void

    func dropEntered(info: DropInfo) {
        guard let draggedItem, draggedItem.id != targetItem.id else { return }
        guard let sourceIndex = orderedIDs.firstIndex(of: draggedItem.id),
              let targetIndex = orderedIDs.firstIndex(of: targetItem.id) else { return }

        withAnimation(.easeInOut(duration: 0.16)) {
            let movedID = orderedIDs.remove(at: sourceIndex)
            orderedIDs.insert(movedID, at: targetIndex)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        let finalOrder = orderedIDs
        draggedItem = nil
        orderedIDs = []
        commitMove(finalOrder)
        return true
    }
}

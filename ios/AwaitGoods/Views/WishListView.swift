import SwiftData
import SwiftUI
import UIKit
import UniformTypeIdentifiers

private enum WishPage: Hashable {
    case detail(UUID)
    case deposit(UUID, request: UUID)
    case add
    case edit(UUID)
}

struct WishListView: View {
    @Environment(\.appLanguage) private var appLanguage
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\WishItem.sortIndex), SortDescriptor(\WishItem.createdAt, order: .reverse)]) private var items: [WishItem]

    @State private var searchText = ""
    @State private var isSearchPresented = false
    @Binding var selectedStatus: WishItemStatus?
    @Binding var wishRoute: WishDeepLink?
    @State private var sortMode = WishSortMode.manual
    @State private var editMode = EditMode.inactive
    @State private var selectedIDs = Set<UUID>()
    @State private var navigationPath: [WishPage] = []
    @State private var routeWaitingForDismissal = false
    @State private var itemToDelete: WishItem?
    @State private var showingBulkDeleteConfirmation = false
    @State private var showingTrash = false
    @State private var linkCopiedToastVisible = false
    @State private var linkCopiedToastToken = UUID()
    @State private var changeEffect: WishChangeEffect?
    @State private var changeEffectToken = UUID()
    @State private var draggedItem: WishItem?
    @State private var dragOrderedIDs: [UUID] = []
    @FocusState private var searchFieldFocused: Bool

    private var isEditing: Bool { editMode.isEditing }
    private var activeItems: [WishItem] { items.filter { !$0.isTrashed } }
    private var trashedItems: [WishItem] { items.filter(\.isTrashed) }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            rootContent
                .navigationDestination(for: WishPage.self) { page in
                    destination(for: page)
                }
        }
        .toolbar(navigationPath.isEmpty && !isEditing ? .visible : .hidden, for: .tabBar)
        .task(id: wishRoute) {
            guard wishRoute != nil, !routeWaitingForDismissal else { return }
            if showingTrash {
                routeWaitingForDismissal = true
                showingTrash = false
            } else {
                presentWishRoute()
            }
        }
    }

    private func presentWishRoute() {
        routeWaitingForDismissal = false
        guard let route = wishRoute else { return }
        wishRoute = nil
        finishEditing()
        switch route {
        case .home:
            selectedStatus = .waiting
            navigationPath = []
        case .add:
            navigationPath = [.add]
        case .wish(let id):
            navigationPath = activeItems.contains { $0.id == id } ? [.detail(id)] : []
        case .deposit(let id):
            navigationPath = activeItems.contains { $0.id == id } ? [.deposit(id, request: UUID())] : []
        }
    }

    private func finishRouteDismissal() {
        guard routeWaitingForDismissal else { return }
        presentWishRoute()
    }

    private var rootContent: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                headerView
                itemScrollView(availableWidth: min(geometry.size.width, 1120))
            }
            .frame(maxWidth: 1120)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle(appLanguage.text("候物"))
        .toolbar(.hidden, for: .navigationBar)
        .background { IllustrationBackdrop() }
        .environment(\.editMode, $editMode)
        .safeAreaInset(edge: .bottom, spacing: 0) { bottomBar }
        .sheet(isPresented: $showingTrash, onDismiss: finishRouteDismissal) { trashSheet }
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
            WidgetSyncService.sync(items: activeItems)
        }
        .onChange(of: selectedStatus) { _, _ in selectedIDs.removeAll() }
        .onChange(of: searchText) { _, _ in selectedIDs.removeAll() }
        .onChange(of: displayedItemIDs) { _, ids in selectedIDs.formIntersection(ids) }
    }

    private func itemScrollView(availableWidth: CGFloat) -> some View {
        let spacing: CGFloat = 12
        let contentWidth = max(availableWidth - 32, 1)
        let count = dynamicTypeSize.isAccessibilitySize
            ? max(1, Int((contentWidth + spacing) / 292))
            : max(2, Int((contentWidth + spacing) / 202))
        let cardWidth = (contentWidth - CGFloat(count - 1) * spacing) / CGFloat(count)
        return GeometryReader { viewport in
            ScrollView {
                if displayedItems.isEmpty {
                    EmptyStateView(
                        state: emptyState,
                        illustrationSize: min(viewport.size.width * 0.7, min(max(viewport.size.height * 0.42, 180), 300)),
                        onAction: handleEmptyStateAction
                    )
                    .frame(minHeight: viewport.size.height)
                } else {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: spacing, alignment: .top), count: count), spacing: spacing) {
                        ForEach(displayedItems) { item in
                            gridCard(for: item, width: cardWidth)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .padding(.bottom, isEditing ? 20 : 88)
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: displayedItemIDs)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .id(selectedStatus)
        }
    }

    private var emptyState: WishListEmptyState {
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return .search }
        if activeItems.isEmpty { return .collection }
        switch selectedStatus {
        case .waiting: return .waiting
        case .bought: return .bought
        case .released: return .released
        case nil: return .collection
        }
    }

    private func handleEmptyStateAction() {
        searchFieldFocused = false
        finishEditing()
        switch emptyState {
        case .collection, .waiting: navigationPath.append(.add)
        case .bought, .released: selectedStatus = nil
        case .search: searchText = ""
        }
    }

    @ViewBuilder
    private func gridCard(for item: WishItem, width: CGFloat) -> some View {
        let card = WishGridCard(
            item: item, width: width, isEditing: isEditing, isSelected: selectedIDs.contains(item.id),
            onOpen: { open(item) },
            onPin: { togglePin(item) },
            onSelect: { beginSelection(item) },
            onEdit: { navigationPath.append(.edit(item.id)) },
            onCopyLink: { copyLink(for: item) },
            onColor: { setMarkColor($0, for: item) },
            onStatus: { updateStatus($0, for: item) },
            onDelete: { itemToDelete = item }
        )
        if isEditing && sortMode == .manual {
            card.onDrag {
                draggedItem = item
                dragOrderedIDs = WishSortIndexPolicy.sorted(activeItems, by: .manual).map(\.id)
                return NSItemProvider(object: item.id.uuidString as NSString)
            }
            .onDrop(of: [UTType.text], delegate: WishDropDelegate(
                targetItem: item, draggedItem: $draggedItem, orderedIDs: $dragOrderedIDs, commitMove: commitDragOrder))
        } else {
            card
        }
    }

    @ViewBuilder
    private func destination(for page: WishPage) -> some View {
        switch page {
        case .add:
            editor(for: nil)
        case .edit(let id):
            if let item = activeItems.first(where: { $0.id == id }) {
                editor(for: item)
            }
        case .detail(let id), .deposit(let id, _):
            if let item = activeItems.first(where: { $0.id == id }) {
                let focusDeposit = if case .deposit = page { true } else { false }
                WishDetailView(item: item, focusDeposit: focusDeposit, onEdit: { navigationPath.append(.edit(id)) }) {
                    persistChanges()
                }
            }
        }
    }

    private func editor(for item: WishItem?) -> some View {
        WishEditorView(item: item, existingItems: activeItems) { _ in
            if item == nil {
                selectedStatus = .waiting
                sortMode = .manual
            }
            persistChanges()
        }
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
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                if isEditing {
                    Button(appLanguage.text("取消"), action: finishEditing)
                        .frame(minWidth: 60, minHeight: 44, alignment: .leading)
                    Spacer(minLength: 4)
                    Text(String(format: appLanguage.text("已选 %d 件"), selectedIDs.count))
                        .font(.headline).foregroundStyle(HWTheme.primaryText)
                    Spacer(minLength: 4)
                    Button(appLanguage.text(allVisibleSelected ? "取消全选" : "全选"), action: toggleSelectAll)
                        .frame(minWidth: 60, minHeight: 44, alignment: .trailing)
                        .disabled(displayedItems.isEmpty)
                } else {
                    AppLogoMark(size: 36, cornerRadius: 10)
                    Text(appLanguage.text("候物"))
                        .font(.system(size: 26, weight: .semibold)).foregroundStyle(HWTheme.primaryText)
                        .lineLimit(1).minimumScaleFactor(0.75)
                    Spacer(minLength: 4)
                    Button(action: toggleSearch) {
                        Image(systemName: isSearchPresented ? "xmark" : "magnifyingglass")
                            .font(.system(size: 20)).frame(width: 44, height: 44)
                    }
                    .foregroundStyle(HWTheme.primaryText)
                    .accessibilityLabel(appLanguage.text("搜索名称、备注或分类"))
                    Button(appLanguage.text("选择"), action: toggleEditing)
                        .font(.subheadline.weight(.medium)).frame(minWidth: 38, minHeight: 44)
                        .disabled(displayedItems.isEmpty)
                    Menu {
                        Section(appLanguage.text("排序")) { sortMenuContent }
                        Section {
                            Button("\(appLanguage.text("回收站")) · \(trashedItems.count)", systemImage: "trash") { showingTrash = true }
                        }
                    } label: {
                        Image(systemName: "ellipsis").font(.system(size: 21)).frame(width: 36, height: 44)
                    }
                    .foregroundStyle(HWTheme.primaryText)
                    .accessibilityLabel(appLanguage.text("更多"))
                }
            }
            .font(.body).foregroundStyle(HWTheme.freshGreen)
            .buttonStyle(.plain)

            if isSearchPresented && !isEditing {
                searchField.transition(.move(edge: .top).combined(with: .opacity))
            }
            statusChips.frame(maxWidth: 520, alignment: .leading)
            HStack {
                Text(String(format: appLanguage.text("%d 件心愿"), displayedItems.count))
                Spacer()
                if !isEditing {
                    Menu { sortMenuContent } label: {
                        Label(appLanguage.text(sortMode.title), systemImage: "arrow.up.arrow.down")
                    }
                }
            }
            .font(.caption).foregroundStyle(HWTheme.secondaryText)
            .frame(minHeight: 32)
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 4)
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
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 6) { statusFilterButtons }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) { statusFilterButtons }
            }
        }
    }

    private var statusFilterButtons: some View {
        Group {
            statusChip(title: appLanguage.text("全部"), count: activeItems.count, status: nil)
            ForEach(WishItemStatus.allCases) { status in
                statusChip(title: appLanguage.text(status.title), count: activeItems.filter { $0.status == status }.count, status: status)
            }
        }
    }

    private func statusChip(title: String, count: Int, status: WishItemStatus?) -> some View {
        let isSelected = selectedStatus == status
        return Button { selectedStatus = status } label: {
            HStack(spacing: 5) {
                Text(title).fontWeight(isSelected ? .semibold : .regular)
                Text("\(count)").font(.caption2.monospacedDigit()).opacity(isSelected ? 0.85 : 0.7)
            }
            .font(.subheadline)
            .fixedSize(horizontal: true, vertical: false)
            .frame(maxWidth: .infinity).frame(minHeight: 36)
            .padding(.horizontal, 10)
            .foregroundStyle(isSelected ? Color.white : HWTheme.secondaryText)
            .background(isSelected ? HWTheme.freshGreen : HWTheme.cardBackground.opacity(0.75), in: Capsule())
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private var floatingAccessoryButtons: some View {
        if !isEditing && !displayedItems.isEmpty {
            HStack {
                Spacer()
                Button {
                    searchFieldFocused = false
                    navigationPath.append(.add)
                } label: {
                    Image(systemName: "plus").font(.system(size: 25, weight: .medium))
                        .foregroundStyle(.white).frame(width: 56, height: 56)
                        .background(HWTheme.freshGreen, in: Circle())
                        .overlay(Circle().stroke(.white.opacity(0.45), lineWidth: 1))
                        .shadow(color: HWTheme.freshGreen.opacity(0.24), radius: 10, y: 5)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(appLanguage.text("新增候物"))
            }
            .padding(.horizontal, 24).padding(.bottom, 18)
            .frame(maxWidth: 1120)
        }
    }

    @ViewBuilder
    private var bottomBar: some View {
        if isEditing {
            HStack(spacing: 0) {
                Menu {
                    ForEach(WishItemStatus.allCases) { status in
                        Button(appLanguage.text(status.title), systemImage: status.iconName) { updateSelectedStatus(status) }
                    }
                } label: { batchLabel("状态", icon: "checkmark.circle", color: HWTheme.freshGreen, hasMenu: true) }
                Menu {
                    ForEach(MarkColor.allCases) { color in
                        Button(appLanguage.text(color.title)) { updateSelectedColor(color) }
                    }
                } label: { batchLabel("标记", icon: "tag", color: HWTheme.freshGreen, hasMenu: true) }
                Button(role: .destructive) { showingBulkDeleteConfirmation = true } label: {
                    batchLabel("移入回收站", icon: "trash", color: HWTheme.dangerRed, hasMenu: false)
                }
            }
            .disabled(selectedIDs.isEmpty)
            .buttonStyle(.plain)
            .padding(.horizontal, 16).padding(.vertical, 8)
            .frame(maxWidth: 680).frame(maxWidth: .infinity)
            .background(HWTheme.cardBackground)
            .overlay(alignment: .top) { Divider().overlay(HWTheme.separator.opacity(0.5)) }
        }
    }

    private func batchLabel(_ title: String, icon: String, color: Color, hasMenu: Bool) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 20))
            HStack(spacing: 4) {
                Text(appLanguage.text(title))
                if hasMenu { Image(systemName: "chevron.down").font(.system(size: 8, weight: .semibold)) }
            }.font(.caption)
        }
        .foregroundStyle(selectedIDs.isEmpty ? HWTheme.tertiaryText : color)
        .frame(maxWidth: .infinity, minHeight: 48)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var sortMenuContent: some View {
        ForEach(WishSortMode.allCases) { mode in
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

        return WishSortIndexPolicy.sorted(result, by: sortMode, manualOrder: dragOrderedIDs)
    }

    private var allVisibleSelected: Bool {
        !displayedItems.isEmpty && Set(displayedItemIDs).isSubset(of: selectedIDs)
    }

    private var selectedItems: [WishItem] {
        displayedItems.filter { selectedIDs.contains($0.id) }
    }

    private func toggleSelectAll() {
        selectedIDs = allVisibleSelected ? [] : Set(displayedItemIDs)
    }

    private func beginSelection(_ item: WishItem) {
        searchFieldFocused = false
        editMode = .active
        selectedIDs = [item.id]
    }

    private func togglePin(_ item: WishItem) {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
            item.isPinned.toggle()
            item.updatedAt = Date()
        }
        persistChanges()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private var displayedItemIDs: [UUID] {
        displayedItems.map(\.id)
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
            navigationPath.append(.detail(item.id))
        }
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
        commitStatus(status, for: selectedItems)
        selectedIDs.removeAll()
    }

    private func updateSelectedColor(_ color: MarkColor) {
        selectedItems.forEach { $0.markColor = color }
        persistChanges()
    }

    private func movePendingItemToTrash() {
        guard let itemToDelete else { return }
        moveToTrash([itemToDelete])
        self.itemToDelete = nil
    }

    private func moveSelectedItemsToTrash() {
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
                    NotificationScheduler.cancel(for: item)
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
            searchFieldFocused = false
            editMode = .active
        }
    }

    private func finishEditing() {
        selectedIDs.removeAll()
        draggedItem = nil
        dragOrderedIDs = []
        editMode = .inactive
    }

    private func persistChanges() {
        try? modelContext.save()
        WidgetSyncService.sync(items: activeItems)
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
            WishRowView(item: item, isEditing: false, isSelected: false, onCheck: {}, onOpen: {})
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

private struct WishDropDelegate: DropDelegate {
    let targetItem: WishItem
    @Binding var draggedItem: WishItem?
    @Binding var orderedIDs: [UUID]
    let commitMove: ([UUID]) -> Void

    func dropEntered(info: DropInfo) {
        guard let draggedItem, draggedItem.id != targetItem.id, draggedItem.isPinned == targetItem.isPinned else { return }
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

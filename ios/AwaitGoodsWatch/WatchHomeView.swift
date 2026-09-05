import SwiftUI
import WatchKit

struct WatchHomeView: View {
    @StateObject private var session = WatchSessionManager.shared
    @State private var filter = WatchWishFilter.all

    var body: some View {
        NavigationStack {
            List {
                if session.items.isEmpty {
                    emptyState
                } else {
                    summarySection
                    wishSection
                    syncSection
                }
            }
            .navigationTitle("候物")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        session.requestSync()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel("从 iPhone 同步")
                }
            }
            .refreshable {
                session.requestSync()
            }
        }
        .onAppear {
            session.start()
            session.requestSync()
        }
    }

    private var summarySection: some View {
        Section {
            HStack(spacing: 10) {
                summaryValue(
                    count: session.items.filter { $0.status == .waiting }.count,
                    title: "想买",
                    icon: "heart.fill",
                    color: .pink
                )

                Divider()

                summaryValue(
                    count: session.items.filter { $0.status == .bought }.count,
                    title: "拥有",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
            }

            Picker("筛选", selection: $filter) {
                ForEach(WatchWishFilter.allCases) { option in
                    Label(option.title, systemImage: option.iconName)
                        .tag(option)
                }
            }
            .pickerStyle(.navigationLink)
        }
    }

    private var wishSection: some View {
        Section(filter.title) {
            if filteredItems.isEmpty {
                Text("这个分类暂无候物")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(filteredItems) { item in
                    NavigationLink {
                        WatchWishDetailView(itemID: item.id, session: session)
                    } label: {
                        WatchWishRow(item: item)
                    }
                }
            }
        }
    }

    private var syncSection: some View {
        Section {
            HStack(spacing: 6) {
                Image(systemName: session.isReachable ? "iphone.radiowaves.left.and.right" : "iphone.slash")
                Text(syncText)
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "shippingbox")
                .font(.system(size: 34))
                .foregroundStyle(.tint)

            Text("暂无候物")
                .font(.headline)

            Text(emptyStateMessage)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("立即同步") {
                session.requestSync()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .listRowBackground(Color.clear)
    }

    private var filteredItems: [WatchWishSnapshot] {
        let items: [WatchWishSnapshot]

        switch filter {
        case .all:
            items = session.items
        case .waiting:
            items = session.items.filter { $0.status == .waiting }
        case .bought:
            items = session.items.filter { $0.status == .bought }
        case .released:
            items = session.items.filter { $0.status == .released }
        }

        return items.sorted { lhs, rhs in
            if lhs.status == rhs.status {
                if lhs.priorityRawValue == rhs.priorityRawValue {
                    return lhs.sortIndex < rhs.sortIndex
                }
                return lhs.priorityRawValue > rhs.priorityRawValue
            }
            return lhs.status.sortOrder < rhs.status.sortOrder
        }
    }

    private var emptyStateMessage: String {
        if session.lastUpdatedAt == nil {
            return "请打开 iPhone 上的候物完成首次同步"
        }
        return "在 iPhone 添加候物后会自动同步到这里"
    }

    private var syncText: String {
        guard let lastUpdatedAt = session.lastUpdatedAt else {
            return session.isReachable ? "iPhone 已连接" : "等待连接 iPhone"
        }

        return "同步于 \(lastUpdatedAt.formatted(date: .omitted, time: .shortened))"
    }

    private func summaryValue(count: Int, title: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Label("\(count)", systemImage: icon)
                .font(.headline)
                .foregroundStyle(color)

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct WatchWishRow: View {
    let item: WatchWishSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Image(systemName: item.status.iconName)
                    .font(.caption)
                    .foregroundStyle(item.status.tintColor)

                Text(item.title)
                    .font(.body.weight(.semibold))
                    .lineLimit(2)
            }

            HStack(spacing: 5) {
                if !item.category.isEmpty {
                    Text(item.category)
                        .lineLimit(1)
                }

                if !item.category.isEmpty, item.price != nil {
                    Text("·")
                }

                if let price = item.price {
                    Text(moneyText(price))
                        .monospacedDigit()
                }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)

            if item.price != nil, item.savedAmount > 0 {
                ProgressView(value: item.savingsProgress)
                    .tint(item.savingsProgress >= 1 ? .green : .mint)
            }
        }
        .padding(.vertical, 2)
    }
}

private struct WatchWishDetailView: View {
    let itemID: UUID
    @ObservedObject var session: WatchSessionManager

    var body: some View {
        List {
            if let item {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.title)
                            .font(.headline)

                        if !item.category.isEmpty {
                            Label(item.category, systemImage: "tag")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }

                        Label(priorityText(item.priorityRawValue), systemImage: "flag")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                if let price = item.price {
                    Section("存钱进度") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(moneyText(item.savedAmount))
                                Spacer()
                                Text(moneyText(price))
                                    .foregroundStyle(.secondary)
                            }
                            .font(.footnote.monospacedDigit())

                            ProgressView(value: item.savingsProgress)
                                .tint(item.savingsProgress >= 1 ? .green : .mint)

                            if item.savedAmount < price {
                                Text("还差 \(moneyText(price - item.savedAmount))")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section("状态") {
                    Picker("当前状态", selection: statusBinding(for: item)) {
                        ForEach(WatchWishStatus.allCases) { status in
                            Label(status.title, systemImage: status.iconName)
                                .tag(status)
                        }
                    }
                    .pickerStyle(.navigationLink)

                    if item.status == .waiting {
                        Button {
                            updateStatus(.bought)
                        } label: {
                            Label("标为已拥有", systemImage: "checkmark.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                }
            } else {
                Text("此候物已在 iPhone 上更新")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("详情")
    }

    private var item: WatchWishSnapshot? {
        session.items.first { $0.id == itemID }
    }

    private func statusBinding(for item: WatchWishSnapshot) -> Binding<WatchWishStatus> {
        Binding(
            get: { item.status },
            set: updateStatus
        )
    }

    private func updateStatus(_ status: WatchWishStatus) {
        session.updateStatus(status, for: itemID)
        WKInterfaceDevice.current().play(status == .bought ? .success : .click)
    }

    private func priorityText(_ priority: Int) -> String {
        switch priority {
        case 3: return "高优先级"
        case 1: return "低优先级"
        default: return "中优先级"
        }
    }
}

private enum WatchWishFilter: String, CaseIterable, Identifiable {
    case all
    case waiting
    case bought
    case released

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "全部"
        case .waiting: return "想买"
        case .bought: return "已拥有"
        case .released: return "放下"
        }
    }

    var iconName: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .waiting: return "heart"
        case .bought: return "checkmark"
        case .released: return "xmark"
        }
    }
}

private extension WatchWishStatus {
    var sortOrder: Int {
        switch self {
        case .waiting: return 0
        case .bought: return 1
        case .released: return 2
        }
    }

    var tintColor: Color {
        switch self {
        case .waiting: return .pink
        case .bought: return .green
        case .released: return .secondary
        }
    }
}

private func moneyText(_ value: Double) -> String {
    "$\(value.formatted(.number.precision(.fractionLength(0...2))))"
}

#Preview {
    WatchHomeView()
}

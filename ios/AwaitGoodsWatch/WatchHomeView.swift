import SwiftUI
import WatchKit

struct WatchHomeView: View {
    @StateObject private var session = WatchSessionManager.shared

    var body: some View {
        NavigationStack {
            Group {
                if session.items.isEmpty {
                    emptyState
                } else {
                    dashboard
                }
            }
            .navigationTitle("候物")
            .background(Color.black.ignoresSafeArea())
        }
        .tint(WatchPalette.cream)
        .onAppear {
            session.start()
            session.requestSync()
        }
    }

    private var dashboard: some View {
        ScrollView {
            VStack(spacing: 7) {
                NavigationLink {
                    WatchWishListView(session: session, initialFilter: .waiting)
                } label: {
                    WatchMetricCard(
                        title: "心愿清单",
                        value: "\(waitingItems.count)",
                        systemImage: "bag",
                        colors: WatchPalette.peachGradient
                    )
                }
                .buttonStyle(WatchCardButtonStyle())
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("心愿清单")
                .accessibilityValue("\(waitingItems.count) 件想买")
                .accessibilityHint("轻点查看心愿清单")

                NavigationLink {
                    WatchSavingsView(session: session)
                } label: {
                    WatchMetricCard(
                        title: "存钱总额",
                        value: moneyText(totalSavedAmount),
                        systemImage: "banknote",
                        colors: WatchPalette.sageGradient
                    )
                }
                .buttonStyle(WatchCardButtonStyle())
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("存钱总额")
                .accessibilityValue(moneyText(totalSavedAmount))
                .accessibilityHint("轻点查看存钱进度")

                NavigationLink {
                    WatchProgressOverviewView(session: session)
                } label: {
                    WatchMetricCard(
                        title: "平均进度",
                        value: percentText(averageSavingsProgress),
                        progress: averageSavingsProgress,
                        colors: WatchPalette.lavenderGradient
                    )
                }
                .buttonStyle(WatchCardButtonStyle())
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("平均进度")
                .accessibilityValue(percentText(averageSavingsProgress))
                .accessibilityHint("轻点查看进度概览")

                syncButton
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 8)
        }
        .scrollIndicators(.hidden)
    }

    private var syncButton: some View {
        Button {
            session.requestSync()
            WKInterfaceDevice.current().play(.click)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: session.isReachable ? "iphone.radiowaves.left.and.right" : "iphone.slash")
                Text(syncText)
                    .lineLimit(1)
                Spacer(minLength: 2)
                Image(systemName: "arrow.clockwise")
            }
            .font(.caption2)
            .foregroundStyle(.white.opacity(0.66))
            .padding(.horizontal, 10)
            .frame(minHeight: 36)
            .background(Color.white.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("从 iPhone 同步")
        .accessibilityValue(syncText)
    }

    private var emptyState: some View {
        ScrollView {
            VStack(spacing: 12) {
                Image(systemName: "bag")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(WatchPalette.ink.opacity(0.62))
                    .frame(width: 68, height: 68)
                    .background(WatchPalette.creamGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

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
                .tint(WatchPalette.sage)
                .foregroundStyle(WatchPalette.ink)
            }
            .padding(.horizontal, 10)
            .padding(.top, 8)
        }
    }

    private var waitingItems: [WatchWishSnapshot] {
        session.items.filter { $0.status == .waiting }
    }

    private var savingsItems: [WatchWishSnapshot] {
        session.items.filter { $0.status == .waiting && $0.price != nil }
    }

    private var totalSavedAmount: Double {
        savingsItems.reduce(0) { $0 + $1.savedAmount }
    }

    private var averageSavingsProgress: Double {
        guard !savingsItems.isEmpty else { return 0 }
        return savingsItems.reduce(0) { $0 + $1.savingsProgress } / Double(savingsItems.count)
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
}

private struct WatchMetricCard: View {
    let title: String
    let value: String
    var systemImage: String?
    var progress: Double?
    let colors: [Color]

    var body: some View {
        HStack(spacing: 10) {
            leadingGraphic

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.medium))
                    .lineLimit(1)

                Text(value)
                    .font(.title3.weight(.semibold).monospacedDigit())
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
            }

            Spacer(minLength: 2)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(WatchPalette.ink.opacity(0.76))
        }
        .foregroundStyle(WatchPalette.ink)
        .padding(.horizontal, 11)
        .frame(maxWidth: .infinity, minHeight: 56)
        .background(
            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.34), lineWidth: 0.8)
        }
    }

    @ViewBuilder
    private var leadingGraphic: some View {
        if let progress {
            WatchProgressRing(progress: progress, size: 34, lineWidth: 4.5, showsValue: true)
        } else if let systemImage {
            Image(systemName: systemImage)
                .font(.system(size: 23, weight: .regular))
                .frame(width: 34, height: 34)
                .background(Color.white.opacity(0.22))
                .clipShape(Circle())
        }
    }
}

private struct WatchCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.86 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

private struct WatchWishListView: View {
    @ObservedObject var session: WatchSessionManager
    @State private var filter: WatchWishFilter

    init(session: WatchSessionManager, initialFilter: WatchWishFilter = .all) {
        self.session = session
        _filter = State(initialValue: initialFilter)
    }

    var body: some View {
        List {
            Picker("筛选", selection: $filter) {
                ForEach(WatchWishFilter.allCases) { option in
                    Label(option.title, systemImage: option.iconName)
                        .tag(option)
                }
            }
            .pickerStyle(.navigationLink)
            .listRowBackground(WatchPalette.cream.opacity(0.16))

            if filteredItems.isEmpty {
                Text("这个分类暂无候物")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.white.opacity(0.06))
            } else {
                ForEach(filteredItems) { item in
                    NavigationLink {
                        WatchWishDetailView(itemID: item.id, session: session)
                    } label: {
                        WatchWishRow(item: item)
                    }
                    .listRowBackground(Color.white.opacity(0.07))
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.black)
        .navigationTitle(filter.title)
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

        return sortedItems(items)
    }
}

private struct WatchWishRow: View {
    let item: WatchWishSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 7) {
                Image(systemName: item.status.iconName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(item.status.tintColor)
                    .frame(width: 20, height: 20)
                    .background(item.status.tintColor.opacity(0.14))
                    .clipShape(Circle())

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
                    .tint(item.status.tintColor)
            }
        }
        .padding(.vertical, 3)
    }
}

private struct WatchSavingsView: View {
    @ObservedObject var session: WatchSessionManager

    var body: some View {
        List {
            WatchAggregateCard(
                title: "已存总额",
                value: moneyText(totalSaved),
                subtitle: "目标 \(moneyText(totalTarget))",
                systemImage: "banknote",
                colors: WatchPalette.sageGradient
            )
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)

            if savingsItems.isEmpty {
                Text("暂无存钱目标")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(savingsItems) { item in
                    NavigationLink {
                        WatchWishDetailView(itemID: item.id, session: session)
                    } label: {
                        VStack(alignment: .leading, spacing: 7) {
                            Text(item.title)
                                .font(.body.weight(.semibold))
                                .lineLimit(2)

                            ProgressView(value: item.savingsProgress)
                                .tint(WatchPalette.sage)

                            HStack {
                                Text(moneyText(item.savedAmount))
                                Spacer()
                                Text(percentText(item.savingsProgress))
                            }
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 3)
                    }
                    .listRowBackground(Color.white.opacity(0.07))
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.black)
        .navigationTitle("存钱进度")
    }

    private var savingsItems: [WatchWishSnapshot] {
        session.items
            .filter { $0.status == .waiting && $0.price != nil }
            .sorted { $0.savingsProgress > $1.savingsProgress }
    }

    private var totalSaved: Double {
        savingsItems.reduce(0) { $0 + $1.savedAmount }
    }

    private var totalTarget: Double {
        savingsItems.reduce(0) { $0 + ($1.price ?? 0) }
    }
}

private struct WatchProgressOverviewView: View {
    @ObservedObject var session: WatchSessionManager

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                VStack(spacing: 8) {
                    WatchProgressRing(
                        progress: averageProgress,
                        size: 86,
                        lineWidth: 9,
                        showsValue: true
                    )

                    Text("平均存钱进度")
                        .font(.headline)
                        .foregroundStyle(WatchPalette.ink)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(WatchPalette.lavenderGradientView)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                statusPill(status: .waiting)
                statusPill(status: .bought)
                statusPill(status: .released)
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 8)
        }
        .scrollIndicators(.hidden)
        .background(Color.black)
        .navigationTitle("进度概览")
    }

    private var trackableItems: [WatchWishSnapshot] {
        session.items.filter { $0.status == .waiting && $0.price != nil }
    }

    private var averageProgress: Double {
        guard !trackableItems.isEmpty else { return 0 }
        return trackableItems.reduce(0) { $0 + $1.savingsProgress } / Double(trackableItems.count)
    }

    private func statusPill(status: WatchWishStatus) -> some View {
        NavigationLink {
            WatchWishListView(session: session, initialFilter: status.filter)
        } label: {
            HStack(spacing: 9) {
                Image(systemName: status.iconName)
                    .foregroundStyle(status.tintColor)
                    .frame(width: 27, height: 27)
                    .background(status.tintColor.opacity(0.14))
                    .clipShape(Circle())

                Text(status.title)
                    .font(.body.weight(.medium))

                Spacer()

                Text("\(session.items.filter { $0.status == status }.count)")
                    .font(.headline.monospacedDigit())

                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 11)
            .frame(minHeight: 48)
            .background(Color.white.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
        .buttonStyle(WatchCardButtonStyle())
    }
}

private struct WatchAggregateCard: View {
    let title: String
    let value: String
    let subtitle: String
    let systemImage: String
    let colors: [Color]

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 24, weight: .regular))
                .frame(width: 38, height: 38)
                .background(Color.white.opacity(0.22))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.medium))
                Text(value)
                    .font(.title3.weight(.semibold).monospacedDigit())
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(WatchPalette.ink.opacity(0.68))
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .foregroundStyle(WatchPalette.ink)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct WatchProgressRing: View {
    let progress: Double
    let size: CGFloat
    let lineWidth: CGFloat
    let showsValue: Bool

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(WatchPalette.ink.opacity(0.16), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: clampedProgress)
                .stroke(
                    WatchPalette.purple,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            if showsValue {
                Text(percentText(clampedProgress))
                    .font(size > 50 ? .headline.monospacedDigit() : .system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundStyle(WatchPalette.ink)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("存钱进度")
        .accessibilityValue(percentText(clampedProgress))
    }
}

private struct WatchWishDetailView: View {
    let itemID: UUID
    @ObservedObject var session: WatchSessionManager

    var body: some View {
        List {
            if let item {
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.title)
                        .font(.headline)
                        .foregroundStyle(WatchPalette.ink)

                    if !item.category.isEmpty {
                        Label(item.category, systemImage: "tag")
                            .font(.footnote)
                            .foregroundStyle(WatchPalette.ink.opacity(0.7))
                    }

                    Label(priorityText(item.priorityRawValue), systemImage: "flag")
                        .font(.footnote)
                        .foregroundStyle(WatchPalette.ink.opacity(0.7))
                }
                .listRowBackground(WatchPalette.peach)

                if let price = item.price {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("存钱进度")
                            .font(.caption.weight(.medium))

                        HStack {
                            Text(moneyText(item.savedAmount))
                            Spacer()
                            Text(moneyText(price))
                                .foregroundStyle(WatchPalette.ink.opacity(0.66))
                        }
                        .font(.footnote.monospacedDigit())

                        ProgressView(value: item.savingsProgress)
                            .tint(WatchPalette.ink.opacity(0.66))

                        if item.savedAmount < price {
                            Text("还差 \(moneyText(price - item.savedAmount))")
                                .font(.caption2)
                                .foregroundStyle(WatchPalette.ink.opacity(0.66))
                        }
                    }
                    .foregroundStyle(WatchPalette.ink)
                    .listRowBackground(WatchPalette.sage)
                }

                Picker("当前状态", selection: statusBinding(for: item)) {
                    ForEach(WatchWishStatus.allCases) { status in
                        Label(status.title, systemImage: status.iconName)
                            .tag(status)
                    }
                }
                .pickerStyle(.navigationLink)
                .listRowBackground(WatchPalette.lavender)

                if item.status == .waiting {
                    Button {
                        updateStatus(.bought)
                    } label: {
                        Label("标为已拥有", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(WatchPalette.sage)
                    .foregroundStyle(WatchPalette.ink)
                }
            } else {
                Text("此候物已在 iPhone 上更新")
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.black)
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
        case .waiting: return WatchPalette.peach
        case .bought: return WatchPalette.sage
        case .released: return WatchPalette.lavender
        }
    }

    var filter: WatchWishFilter {
        switch self {
        case .waiting: return .waiting
        case .bought: return .bought
        case .released: return .released
        }
    }
}

private enum WatchPalette {
    static let ink = Color(red: 0.18, green: 0.16, blue: 0.14)
    static let cream = Color(red: 0.95, green: 0.91, blue: 0.84)
    static let peach = Color(red: 0.91, green: 0.77, blue: 0.69)
    static let sage = Color(red: 0.72, green: 0.80, blue: 0.65)
    static let lavender = Color(red: 0.73, green: 0.69, blue: 0.84)
    static let purple = Color(red: 0.39, green: 0.31, blue: 0.59)

    static let peachGradient = [
        Color(red: 0.97, green: 0.87, blue: 0.82),
        Color(red: 0.87, green: 0.70, blue: 0.63)
    ]

    static let sageGradient = [
        Color(red: 0.86, green: 0.90, blue: 0.78),
        Color(red: 0.64, green: 0.75, blue: 0.57)
    ]

    static let lavenderGradient = [
        Color(red: 0.86, green: 0.83, blue: 0.93),
        Color(red: 0.65, green: 0.59, blue: 0.78)
    ]

    static var creamGradient: LinearGradient {
        LinearGradient(
            colors: [Color.white.opacity(0.96), cream.opacity(0.86)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var lavenderGradientView: LinearGradient {
        LinearGradient(colors: lavenderGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

private func sortedItems(_ items: [WatchWishSnapshot]) -> [WatchWishSnapshot] {
    items.sorted { lhs, rhs in
        if lhs.status == rhs.status {
            if lhs.priorityRawValue == rhs.priorityRawValue {
                return lhs.sortIndex < rhs.sortIndex
            }
            return lhs.priorityRawValue > rhs.priorityRawValue
        }
        return lhs.status.sortOrder < rhs.status.sortOrder
    }
}

private func moneyText(_ value: Double) -> String {
    "$\(value.formatted(.number.precision(.fractionLength(0...2))))"
}

private func percentText(_ progress: Double) -> String {
    "\(Int((min(max(progress, 0), 1) * 100).rounded()))%"
}

#Preview {
    WatchHomeView()
}

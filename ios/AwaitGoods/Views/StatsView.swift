import Foundation
import SwiftData
import SwiftUI

struct StatsView: View {
    @Environment(\.appLanguage) private var appLanguage
    @Query(sort: [SortDescriptor(\WishItem.sortIndex), SortDescriptor(\WishItem.createdAt, order: .reverse)]) private var items: [WishItem]

    private var activeItems: [WishItem] {
        items.filter { !$0.isTrashed }
    }

    private var pricedItems: [WishItem] {
        activeItems.filter { $0.price != nil }
    }

    private var totalBudget: Double {
        pricedItems.reduce(0) { $0 + ($1.price ?? 0) }
    }

    private var totalSaved: Double {
        activeItems.reduce(0) { $0 + $1.savedAmountValue }
    }

    private var completionRatio: Double {
        guard totalBudget > 0 else { return 0 }
        return min(max(totalSaved / totalBudget, 0), 1)
    }

    private var categoryStats: [CategoryStat] {
        let grouped = Dictionary(grouping: activeItems) { item in
            let value = item.category.trimmingCharacters(in: .whitespacesAndNewlines)
            return value.isEmpty ? appLanguage.text("未分类") : appLanguage.text(value)
        }

        return grouped
            .map { CategoryStat(name: $0.key, count: $0.value.count, budget: $0.value.reduce(0) { $0 + ($1.price ?? 0) }) }
            .sorted { $0.count == $1.count ? $0.name < $1.name : $0.count > $1.count }
    }

    private var priorityStats: [PriorityStat] {
        WishPriority.allCases.reversed().map { priority in
            let matches = activeItems.filter { $0.priority == priority }
            return PriorityStat(
                priority: priority,
                count: matches.count,
                budget: matches.reduce(0) { $0 + ($1.price ?? 0) }
            )
        }
    }

    private var progressStats: [ProgressStat] {
        [
            ProgressStat(title: appLanguage.text("已完成 100%"), count: activeItems.filter { $0.savingsProgress >= 1 }.count, color: HWTheme.freshGreen),
            ProgressStat(title: appLanguage.text("进度 30%–99%"), count: activeItems.filter { $0.savingsProgress >= 0.3 && $0.savingsProgress < 1 }.count, color: HWTheme.apricot),
            ProgressStat(title: appLanguage.text("进度低于 30%"), count: activeItems.filter { $0.savingsProgress < 0.3 }.count, color: HWTheme.tertiaryText)
        ]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    overviewHeader
                    metricsGrid
                    priorityOverview
                    progressOverview
                    statusOverview
                    categoryOverview
                    recentOverview
                }
                .padding(14)
                .padding(.top, 6)
                .padding(.bottom, 20)
            }
            .background(HWTheme.pageBackground.ignoresSafeArea())
            .navigationTitle(appLanguage.text("统计"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var overviewHeader: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(appLanguage.text("看见预算，决定节奏"))
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(HWTheme.primaryText)

            Text(String(format: appLanguage.text("共 %d 件候物，已记录的计划都在这里"), activeItems.count))
                .font(.system(size: 14))
                .foregroundStyle(HWTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 2)
    }

    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            metricCard(title: appLanguage.text("总预算"), value: moneyText(totalBudget), icon: "target", color: HWTheme.freshGreen)
            metricCard(title: appLanguage.text("已存金额"), value: moneyText(totalSaved), icon: "banknote", color: HWTheme.apricot)
            metricCard(title: appLanguage.text("完成率"), value: "\(Int((completionRatio * 100).rounded()))%", icon: "chart.line.uptrend.xyaxis", color: HWTheme.softBlueGray)
            metricCard(title: appLanguage.text("待决定"), value: "\(activeItems.filter { $0.status == .waiting }.count)", icon: "heart", color: HWTheme.blossom)
        }
    }

    private func metricCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(color)
                    .frame(width: 25, height: 25)
                    .background(color.opacity(0.13))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(HWTheme.secondaryText)
            }

            Text(value)
                .font(.system(size: 21, weight: .semibold).monospacedDigit())
                .foregroundStyle(HWTheme.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, minHeight: 86, alignment: .leading)
        .padding(12)
        .background(HWTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(HWTheme.cardBorder.opacity(0.52), lineWidth: 0.8)
        )
    }

    private var statusOverview: some View {
        statsSection(appLanguage.text("状态概览")) {
            ForEach(WishItemStatus.allCases) { status in
                let count = activeItems.filter { $0.status == status }.count
                HStack(spacing: 9) {
                    Image(systemName: status.iconName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(statusColor(status))
                        .frame(width: 24, height: 24)

                    Text(appLanguage.text(status.title))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(HWTheme.primaryText)

                    Spacer()

                    Text("\(count)")
                        .font(.system(size: 14, weight: .semibold).monospacedDigit())
                        .foregroundStyle(HWTheme.secondaryText)
                }
                .padding(.vertical, 5)
            }
        }
    }

    private var priorityOverview: some View {
        statsSection(appLanguage.text("预算分布")) {
            ForEach(priorityStats) { stat in
                distributionRow(
                    title: "\(appLanguage.text(stat.priority.title))\(appLanguage.text("优先级"))",
                    value: moneyText(stat.budget),
                    count: stat.count,
                    share: totalBudget > 0 ? stat.budget / totalBudget : 0,
                    color: priorityColor(stat.priority)
                )
            }
        }
    }

    private var progressOverview: some View {
        statsSection(appLanguage.text("进度分布")) {
            ForEach(progressStats) { stat in
                distributionRow(
                    title: stat.title,
                    value: "\(stat.count)",
                    count: stat.count,
                    share: activeItems.isEmpty ? 0 : Double(stat.count) / Double(activeItems.count),
                    color: stat.color
                )
            }
        }
    }

    private var categoryOverview: some View {
        statsSection(appLanguage.text("分类分布")) {
            if categoryStats.isEmpty {
                Text(appLanguage.text("暂无可统计的候物"))
                    .font(.system(size: 14))
                    .foregroundStyle(HWTheme.secondaryText)
                    .padding(.vertical, 6)
            } else {
                ForEach(categoryStats) { stat in
                    VStack(alignment: .leading, spacing: 7) {
                        HStack(spacing: 8) {
                            Text(stat.name)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(HWTheme.primaryText)

                            Spacer()

                            Text("\(stat.count) · \(moneyText(stat.budget))")
                                .font(.system(size: 13, weight: .semibold).monospacedDigit())
                                .foregroundStyle(HWTheme.secondaryText)
                        }

                        GeometryReader { proxy in
                            ZStack(alignment: .leading) {
                                Capsule().fill(HWTheme.fieldBackground)
                                Capsule()
                                    .fill(HWTheme.freshGreen.opacity(0.76))
                                    .frame(width: proxy.size.width * stat.share(total: activeItems.count))
                            }
                        }
                        .frame(height: 6)
                    }
                    .padding(.vertical, 5)
                }
            }
        }
    }

    private var recentOverview: some View {
        statsSection(appLanguage.text("最近添加")) {
            if activeItems.isEmpty {
                Text(appLanguage.text("暂无可统计的候物"))
                    .font(.system(size: 14))
                    .foregroundStyle(HWTheme.secondaryText)
                    .padding(.vertical, 6)
            } else {
                ForEach(Array(activeItems.sorted { $0.createdAt > $1.createdAt }.prefix(3))) { item in
                    HStack(spacing: 10) {
                        Image(systemName: "bag")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(HWTheme.freshGreen)
                            .frame(width: 32, height: 32)
                            .background(HWTheme.mint.opacity(0.17))
                            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

                        Text(item.title)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(HWTheme.primaryText)
                            .lineLimit(1)

                        Spacer()

                        if let price = item.price {
                            Text(moneyText(price))
                                .font(.system(size: 13, weight: .semibold).monospacedDigit())
                                .foregroundStyle(HWTheme.secondaryText)
                        }
                    }
                    .padding(.vertical, 5)
                }
            }
        }
    }

    private func distributionRow(title: String, value: String, count: Int, share: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 8) {
                Circle()
                    .fill(color)
                    .frame(width: 7, height: 7)

                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(HWTheme.primaryText)

                Spacer()

                Text(value)
                    .font(.system(size: 13, weight: .semibold).monospacedDigit())
                    .foregroundStyle(HWTheme.secondaryText)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(HWTheme.fieldBackground)
                    Capsule()
                        .fill(color.opacity(0.78))
                        .frame(width: proxy.size.width * min(max(share, 0), 1))
                }
            }
            .frame(height: 6)
        }
        .padding(.vertical, 5)
        .accessibilityLabel("\(title) \(count)")
    }

    private func statsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(HWTheme.primaryText)

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(HWTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(HWTheme.cardBorder.opacity(0.52), lineWidth: 0.8)
        )
    }

    private func statusColor(_ status: WishItemStatus) -> Color {
        switch status {
        case .waiting: return HWTheme.freshGreen
        case .bought: return HWTheme.softBlueGray
        case .released: return HWTheme.tertiaryText
        }
    }

    private func priorityColor(_ priority: WishPriority) -> Color {
        switch priority {
        case .high: return HWTheme.dangerRed
        case .medium: return HWTheme.apricot
        case .low: return HWTheme.freshGreen
        }
    }

    private func moneyText(_ value: Double) -> String {
        "$\(value.formatted(.number.precision(.fractionLength(0...0))))"
    }
}

private struct CategoryStat: Identifiable {
    let name: String
    let count: Int
    let budget: Double

    var id: String { name }

    func share(total: Int) -> Double {
        guard total > 0 else { return 0 }
        return min(max(Double(count) / Double(total), 0), 1)
    }
}

private struct PriorityStat: Identifiable {
    let priority: WishPriority
    let count: Int
    let budget: Double

    var id: Int { priority.rawValue }
}

private struct ProgressStat: Identifiable {
    let title: String
    let count: Int
    let color: Color

    var id: String { title }
}

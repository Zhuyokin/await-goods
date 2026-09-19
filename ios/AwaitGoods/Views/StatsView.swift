import Foundation
import SwiftData
import SwiftUI

struct StatsView: View {
    @Environment(\.appLanguage) private var appLanguage
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Query(sort: [SortDescriptor(\WishItem.sortIndex), SortDescriptor(\WishItem.createdAt, order: .reverse)]) private var items: [WishItem]

    let onOpenWishList: (WishItemStatus?) -> Void

    var body: some View {
        let stats = WishStatistics(items: items)

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    pageHeader
                    if stats.activeItems.isEmpty {
                        emptyOverview
                    } else {
                        savingsOverview(stats)
                        statusOverview(stats)
                        if !stats.waitingItems.isEmpty {
                            categoryOverview(stats)
                        }
                    }
                }
                .frame(maxWidth: 680)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 18)
                .padding(.top, 24)
                .padding(.bottom, 28)
            }
            .background { WillowBackdrop(illustrationSize: 480) }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var pageHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(appLanguage.text("统计"))
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(HWTheme.primaryText)
            Text(appLanguage.text("你的每一个愿望，都在慢慢靠近"))
                .font(.subheadline)
                .foregroundStyle(HWTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 6)
        .padding(.bottom, 2)
    }

    private func savingsOverview(_ stats: WishStatistics) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 10) {
                badge("heart.fill", color: HWTheme.freshGreen, size: 36)
                VStack(alignment: .leading, spacing: 4) {
                    Text(appLanguage.text("心愿总览"))
                        .font(.headline)
                        .foregroundStyle(HWTheme.primaryText)
                    Text(String(format: appLanguage.text("共 %d 件候物"), stats.activeItems.count))
                        .font(.caption)
                        .foregroundStyle(HWTheme.secondaryText)
                }
                Spacer(minLength: 4)
                Button {
                    onOpenWishList(.waiting)
                } label: {
                    HStack(spacing: 6) {
                        Text(appLanguage.text("查看"))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(HWTheme.freshGreen)
                    .padding(.horizontal, 13)
                    .frame(minHeight: 36)
                    .background(HWTheme.mint.opacity(0.24), in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(appLanguage.text("查看"))\(appLanguage.text("想买"))")
            }

            if stats.budget > 0 {
                VStack(alignment: .leading, spacing: 6) {
                    Text(appLanguage.text("还需存入"))
                        .font(.subheadline)
                        .foregroundStyle(HWTheme.secondaryText)
                    Text(moneyText(stats.remaining))
                        .font(.system(size: 36, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(HWTheme.primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.55)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 9) {
                    HStack {
                        Text(appLanguage.text("存钱进度"))
                        Spacer()
                        Text("\(Int(stats.progress * 100))%")
                            .monospacedDigit()
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(HWTheme.secondaryText)
                    progressTrack(stats.progress, color: HWTheme.freshGreen, height: 6)
                        .accessibilityLabel(appLanguage.text("存钱进度"))
                        .accessibilityValue("\(Int(stats.progress * 100))%")
                }

                Divider().overlay(HWTheme.separator.opacity(0.5))
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 12) {
                        amountColumn(title: "已存金额", value: stats.saved, icon: "banknote")
                        Rectangle()
                            .fill(HWTheme.separator.opacity(0.6))
                            .frame(width: 1, height: 40)
                            .accessibilityHidden(true)
                        amountColumn(title: "目标总额", value: stats.budget, icon: "scope")
                    }
                    VStack(alignment: .leading, spacing: 14) {
                        amountColumn(title: "已存金额", value: stats.saved, icon: "banknote")
                        amountColumn(title: "目标总额", value: stats.budget, icon: "scope")
                    }
                }
                Divider().overlay(HWTheme.separator.opacity(0.5))

                HStack(alignment: .top, spacing: 7) {
                    Image(systemName: "doc.text")
                        .foregroundStyle(HWTheme.freshGreen)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(appLanguage.text("仅统计「想买」中已填写目标价格的物品"))
                        if stats.unpricedCount > 0 {
                            Text(String(format: appLanguage.text("另有 %d 件尚未填写目标价格"), stats.unpricedCount))
                        }
                    }
                    .foregroundStyle(HWTheme.secondaryText)
                }
                .font(.caption)
                .fixedSize(horizontal: false, vertical: true)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text(appLanguage.text(stats.waitingItems.isEmpty ? "还没有想买的物品" : "目标价格还未确定"))
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(HWTheme.primaryText)
                    Text(appLanguage.text(stats.waitingItems.isEmpty ? "添加想买的物品后，在这里查看预算与存钱进度" : "为想买的物品填写目标价格后，即可查看还需金额与存钱进度"))
                        .font(.subheadline)
                        .foregroundStyle(HWTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 8)
            }
        }
        .padding(18)
        .botanicalCard()
    }

    private func amountColumn(title: String, value: Double, icon: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            badge(icon, color: HWTheme.freshGreen, size: 27)
            VStack(alignment: .leading, spacing: 5) {
                Text(appLanguage.text(title))
                    .font(.caption)
                    .foregroundStyle(HWTheme.secondaryText)
                Text(moneyText(value))
                    .font(.system(size: 18, weight: .semibold, design: .rounded).monospacedDigit())
                    .foregroundStyle(HWTheme.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func statusOverview(_ stats: WishStatistics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionTitle("状态概览")
                Spacer(minLength: 8)
                Button {
                    onOpenWishList(nil)
                } label: {
                    HStack(spacing: 6) {
                        Text(appLanguage.text("查看全部"))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .font(.caption)
                    .foregroundStyle(HWTheme.secondaryText)
                    .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
            }

            let layout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(spacing: 10))
                : AnyLayout(HStackLayout(alignment: .top, spacing: 9))
            layout {
                ForEach(WishItemStatus.allCases) { status in
                    statusCard(status, count: stats.items(for: status).count)
                }
            }
        }
    }

    private func statusCard(_ status: WishItemStatus, count: Int) -> some View {
        Button {
            onOpenWishList(status)
        } label: {
            VStack(alignment: .leading, spacing: 9) {
                badge(status == .waiting ? "heart.fill" : status.iconName, color: statusColor(status), size: 32)
                Text("\(count)")
                    .font(.system(size: 29, weight: .semibold, design: .rounded).monospacedDigit())
                    .foregroundStyle(HWTheme.primaryText)
                Text(appLanguage.text(status.title))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(HWTheme.secondaryText)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(appLanguage.text(statusCaption(status)))
                        .font(.system(size: 10))
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .medium))
                }
                .foregroundStyle(HWTheme.tertiaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .botanicalCard(cornerRadius: 18)
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(appLanguage.text(status.title))，\(String(format: appLanguage.text("%d 件"), count))")
    }

    private func categoryOverview(_ stats: WishStatistics) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                sectionTitle("想买的分类")
                Spacer(minLength: 8)
                Text(appLanguage.text("按物品数量"))
                    .font(.caption)
                    .foregroundStyle(HWTheme.secondaryText)
            }
            VStack(spacing: 0) {
                ForEach(Array(stats.categories.enumerated()), id: \.element.id) { index, category in
                    let color = categoryColor(index)
                    Button {
                        onOpenWishList(.waiting)
                    } label: {
                        HStack(spacing: 12) {
                            badge(categoryIcon(category.name), color: color, size: 34)
                            VStack(alignment: .leading, spacing: 9) {
                                Text(appLanguage.text(category.name.isEmpty ? "未分类" : category.name))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(HWTheme.primaryText)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                progressTrack(Double(category.count) / Double(stats.waitingItems.count), color: color, height: 4)
                                    .accessibilityHidden(true)
                            }
                            Text(String(format: appLanguage.text("%d 件"), category.count))
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(HWTheme.secondaryText)
                                .fixedSize()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(HWTheme.tertiaryText)
                        }
                        .padding(.vertical, 15)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    if index < stats.categories.count - 1 {
                        Divider()
                            .overlay(HWTheme.separator.opacity(0.35))
                            .padding(.leading, 46)
                    }
                }
            }
            .padding(.horizontal, 15)
            .botanicalCard()
        }
    }

    private var emptyOverview: some View {
        VStack(spacing: 14) {
            badge("heart", color: HWTheme.freshGreen, size: 64)
            Text(appLanguage.text("暂无可统计的候物"))
                .font(.headline)
                .foregroundStyle(HWTheme.primaryText)
            Text(appLanguage.text("在首页添加心愿后，预算与状态会显示在这里"))
                .font(.subheadline)
                .foregroundStyle(HWTheme.secondaryText)
                .multilineTextAlignment(.center)
            Button(appLanguage.text("查看")) { onOpenWishList(nil) }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(HWTheme.freshGreen)
                .frame(minHeight: 44)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.vertical, 36)
        .botanicalCard()
    }

    private func badge(_ icon: String, color: Color, size: CGFloat) -> some View {
        Image(systemName: icon)
            .font(.system(size: size * 0.47, weight: .medium))
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .background(color.opacity(0.11), in: Circle())
            .accessibilityHidden(true)
    }

    private func progressTrack(_ progress: Double, color: Color, height: CGFloat) -> some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(HWTheme.separator.opacity(0.36))
                Capsule()
                    .fill(LinearGradient(colors: [color.opacity(0.65), color], startPoint: .leading, endPoint: .trailing))
                    .frame(width: proxy.size.width * min(max(progress, 0), 1))
            }
        }
        .frame(height: height)
    }

    private func sectionTitle(_ key: String) -> some View {
        Text(appLanguage.text(key))
            .font(.title3.weight(.semibold))
            .foregroundStyle(HWTheme.primaryText)
    }

    private func statusColor(_ status: WishItemStatus) -> Color {
        switch status {
        case .waiting: return HWTheme.freshGreen
        case .bought: return HWTheme.softBlueGray
        case .released: return HWTheme.dangerRed.opacity(0.65)
        }
    }

    private func statusCaption(_ status: WishItemStatus) -> String {
        switch status {
        case .waiting: return "正在努力攒钱"
        case .bought: return "享受已达成的快乐"
        case .released: return "理性消费更自由"
        }
    }

    private func categoryColor(_ index: Int) -> Color {
        let colors = [HWTheme.freshGreen, HWTheme.softBlueGray, HWTheme.blossom, HWTheme.softWood]
        return colors[index % colors.count]
    }

    private func categoryIcon(_ category: String) -> String {
        switch category {
        case "数码": return "laptopcomputer"
        case "衣物": return "tshirt"
        case "家居": return "house"
        case "书影音": return "book.closed"
        case "礼物": return "gift"
        case "运动": return "figure.run"
        default: return "tag"
        }
    }

    private func moneyText(_ value: Double) -> String {
        "$\(value.formatted(.number.precision(.fractionLength(0...2))))"
    }
}

private extension View {
    func botanicalCard(cornerRadius: CGFloat = 24) -> some View {
        background {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(HWTheme.cardBackground.opacity(0.88))
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(HWTheme.cardBackground.opacity(0.95), lineWidth: 1)
                }
                .shadow(color: HWTheme.softShadow.opacity(0.38), radius: 12, x: 0, y: 5)
        }
    }
}

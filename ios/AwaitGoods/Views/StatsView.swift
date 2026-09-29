import Foundation
import SwiftData
import SwiftUI

struct StatsView: View {
    @Environment(\.appLanguage) private var appLanguage
    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @AppStorage(WishCurrency.selectionKey) private var statisticsCurrencyCode = "USD"
    @Query(sort: [SortDescriptor(\WishItem.sortIndex), SortDescriptor(\WishItem.createdAt, order: .reverse)]) private var items: [WishItem]

    let onOpenWishList: (WishItemStatus?) -> Void

    var body: some View {
        let stats = WishStatistics(items: items, currencyCode: statisticsCurrencyCode)

        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        pageHeader
                        if stats.activeItems.isEmpty {
                            emptyOverview
                        } else {
                            if geometry.size.width >= 900 && !dynamicTypeSize.isAccessibilitySize {
                                HStack(alignment: .top, spacing: 16) {
                                    savingsOverview(stats).frame(maxWidth: .infinity)
                                    VStack(spacing: 14) {
                                        statusOverview(stats)
                                        if !stats.waitingItems.isEmpty { categoryOverview(stats) }
                                    }.frame(maxWidth: .infinity)
                                }
                            } else {
                                savingsOverview(stats)
                                statusOverview(stats)
                                if !stats.waitingItems.isEmpty { categoryOverview(stats) }
                            }
                            recentItems(stats)
                        }
                    }
                    .frame(maxWidth: geometry.size.width >= 900 ? 1120 : 680)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 18)
                    .padding(.top, 20)
                    .padding(.bottom, 28)
                }
            }
            .background { IllustrationBackdrop(illustrationSize: 480) }
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
        VStack(alignment: .leading, spacing: 10) {
            let layout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 14))
                : AnyLayout(HStackLayout(alignment: .top, spacing: 12))
            layout {
                VStack(alignment: .leading, spacing: 13) {
                    Button { onOpenWishList(nil) } label: {
                        HStack(alignment: .top, spacing: 10) {
                            badge("heart.fill", color: HWTheme.freshGreen, size: 32)
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 9) {
                                    Text(appLanguage.text("心愿总览"))
                                        .font(.headline).foregroundStyle(HWTheme.primaryText)
                                    Image(systemName: "chevron.right").font(.system(size: 11, weight: .semibold))
                                }
                                Text(String(format: appLanguage.text("共 %d 件心愿"), stats.activeItems.count))
                                    .font(.caption)
                            }.foregroundStyle(HWTheme.secondaryText)
                            Spacer(minLength: 0)
                        }.frame(minHeight: 44, alignment: .leading).contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Text(String(format: appLanguage.text("当前币种 · %d 件想买的物品"), stats.currencyItems.count))
                        .font(.caption2)
                        .foregroundStyle(HWTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    if stats.budget > 0 {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(appLanguage.text("还需存入"))
                                .font(.subheadline).foregroundStyle(HWTheme.secondaryText)
                            Text(moneyText(stats.remaining, code: stats.currencyCode))
                                .font(.system(size: 34, weight: .bold, design: .rounded).monospacedDigit())
                                .foregroundStyle(HWTheme.primaryText)
                                .lineLimit(1).minimumScaleFactor(0.55)
                        }
                    }
                }.frame(maxWidth: .infinity, alignment: .leading)
                VStack(spacing: 13) {
                    currencySelection(stats).frame(minHeight: 44)
                    completionRing(stats)
                }
            }

            if stats.budget > 0 {
                cardDivider
                VStack(spacing: 7) {
                    HStack {
                        Text(appLanguage.text("存钱进度"))
                        Spacer()
                        Text("\(Int(stats.progress * 100))%").foregroundStyle(HWTheme.freshGreen).monospacedDigit()
                    }.font(.subheadline.weight(.semibold)).foregroundStyle(HWTheme.secondaryText)
                    progressTrack(stats.progress, color: HWTheme.freshGreen, height: 7)
                        .accessibilityLabel(appLanguage.text("存钱进度"))
                        .accessibilityValue("\(Int(stats.progress * 100))%")
                }
                cardDivider
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 12) {
                        amountColumn(title: "已存金额", value: stats.saved, icon: "banknote", code: stats.currencyCode)
                        Rectangle().fill(HWTheme.separator.opacity(0.5)).frame(width: 1, height: 43).accessibilityHidden(true)
                        amountColumn(title: "目标总额", value: stats.budget, icon: "scope", code: stats.currencyCode)
                    }
                    VStack(alignment: .leading, spacing: 14) {
                        amountColumn(title: "已存金额", value: stats.saved, icon: "banknote", code: stats.currencyCode)
                        amountColumn(title: "目标总额", value: stats.budget, icon: "scope", code: stats.currencyCode)
                    }
                }
                cardDivider
                Button { onOpenWishList(.waiting) } label: {
                    HStack(alignment: .center, spacing: 8) {
                        Image(systemName: "doc.text").font(.system(size: 14))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(appLanguage.text("仅统计「想买」中已填写目标价格的物品"))
                            if stats.unpricedCount > 0 {
                                Text(String(format: appLanguage.text("另有 %d 件尚未填写目标价格"), stats.unpricedCount))
                            }
                        }.font(.system(size: 11)).fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right").font(.system(size: 10, weight: .medium))
                    }.foregroundStyle(HWTheme.secondaryText).frame(minHeight: 30).contentShape(Rectangle())
                }.buttonStyle(.plain)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text(appLanguage.text(stats.waitingItems.isEmpty ? "还没有想买的物品" : "目标价格还未确定"))
                        .font(.title3.weight(.semibold)).foregroundStyle(HWTheme.primaryText)
                    Text(appLanguage.text(stats.waitingItems.isEmpty ? "添加想买的物品后，在这里查看预算与存钱进度" : "为想买的物品填写目标价格后，即可查看还需金额与存钱进度"))
                        .font(.subheadline).foregroundStyle(HWTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }.padding(.vertical, 8)
            }
        }.padding(16).botanicalCard()
    }

    private var cardDivider: some View {
        Rectangle().fill(HWTheme.separator.opacity(0.4)).frame(height: 0.5).padding(.vertical, 2)
    }

    private func currencySelection(_ stats: WishStatistics) -> some View {
        Menu {
            Picker(appLanguage.text("币种"), selection: $statisticsCurrencyCode) {
                ForEach(stats.availableCurrencyCodes, id: \.self) { code in
                    Text("\(appLanguage.text(WishCurrency(rawValue: code)?.title ?? code)) · \(code)")
                        .tag(code)
                }
            }
        } label: {
            HStack(spacing: 5) {
                Text(stats.currencyCode).fontWeight(.semibold)
                Image(systemName: "chevron.down").font(.system(size: 9, weight: .semibold))
            }
            .font(.subheadline)
            .foregroundStyle(HWTheme.freshGreen)
            .padding(.horizontal, 12)
            .frame(minHeight: 36)
            .background(HWTheme.fieldBackground, in: Capsule())
        }
        .disabled(stats.availableCurrencyCodes.count < 2)
        .accessibilityLabel("\(appLanguage.text("币种")) \(appLanguage.text(WishCurrency(rawValue: stats.currencyCode)?.title ?? stats.currencyCode))")
    }

    private func completionRing(_ stats: WishStatistics) -> some View {
        Button { onOpenWishList(.bought) } label: {
            ZStack {
                Circle().stroke(HWTheme.freshGreen.opacity(0.11), lineWidth: 8)
                if stats.completionProgress > 0 {
                    Circle().trim(from: 0, to: stats.completionProgress)
                        .stroke(HWTheme.freshGreen, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                VStack(spacing: 4) {
                    Text(appLanguage.text("已完成")).font(.system(size: 10))
                    Text("\(stats.completedCount) / \(stats.activeItems.count)")
                        .font(.system(size: 15, weight: .semibold)).foregroundStyle(HWTheme.primaryText)
                    Text("\(Int(stats.completionProgress * 100))%").font(.system(size: 11, weight: .medium))
                }.foregroundStyle(HWTheme.secondaryText).monospacedDigit()
            }.frame(width: 80, height: 80).padding(5)
        }.buttonStyle(.plain)
            .accessibilityLabel("\(appLanguage.text("已完成")) \(stats.completedCount) / \(stats.activeItems.count)")
    }

    private func amountColumn(title: String, value: Double, icon: String, code: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            badge(icon, color: HWTheme.freshGreen, size: 27)
            VStack(alignment: .leading, spacing: 5) {
                Text(appLanguage.text(title))
                    .font(.caption)
                    .foregroundStyle(HWTheme.secondaryText)
                Text(moneyText(value, code: code))
                    .font(.system(size: 19, weight: .semibold, design: .rounded).monospacedDigit())
                    .foregroundStyle(HWTheme.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func statusOverview(_ stats: WishStatistics) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("状态概览") { onOpenWishList(nil) }
            let layout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(spacing: 8))
                : AnyLayout(HStackLayout(alignment: .top, spacing: 8))
            layout {
                ForEach(WishItemStatus.allCases) { status in
                    statusCard(status, count: stats.items(for: status).count)
                }
            }
        }.padding(12).botanicalCard()
    }

    private func statusCard(_ status: WishItemStatus, count: Int) -> some View {
        let color = statusColor(status)
        return Button { onOpenWishList(status) } label: {
            VStack(alignment: .leading, spacing: 6) {
                badge(status == .waiting ? "heart.fill" : status.iconName, color: color, size: 28)
                Text("\(count)")
                    .font(.system(size: 25, weight: .semibold, design: .rounded).monospacedDigit())
                    .foregroundStyle(HWTheme.primaryText)
                Text(appLanguage.text(status.title))
                    .font(.subheadline.weight(.semibold)).foregroundStyle(HWTheme.primaryText)
                    .lineLimit(2).minimumScaleFactor(0.8)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(appLanguage.text(statusCaption(status)))
                        .font(.system(size: 9)).lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right").font(.system(size: 9, weight: .medium))
                }.foregroundStyle(HWTheme.tertiaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding(10)
            .background(LinearGradient(colors: [color.opacity(colorScheme == .dark ? 0.18 : 0.07), color.opacity(0.035)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 13))
            .contentShape(RoundedRectangle(cornerRadius: 13))
        }.buttonStyle(.plain)
            .accessibilityLabel("\(appLanguage.text(status.title))，\(String(format: appLanguage.text("%d 件"), count))")
    }

    private func categoryOverview(_ stats: WishStatistics) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                sectionTitle("想买的分类")
                Spacer(minLength: 8)
                Label(appLanguage.text("按物品数量"), systemImage: "arrow.up.arrow.down")
                    .font(.system(size: 10)).foregroundStyle(HWTheme.secondaryText)
            }
            VStack(spacing: 4) {
                ForEach(Array(stats.categories.enumerated()), id: \.element.id) { index, category in
                    let color = categoryColor(index)
                    Button { onOpenWishList(.waiting) } label: {
                        HStack(spacing: 10) {
                            badge(categoryIcon(category.name), color: color, size: 30)
                            VStack(alignment: .leading, spacing: 5) {
                                Text(appLanguage.text(category.name.isEmpty ? "未分类" : category.name))
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(HWTheme.primaryText)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                progressTrack(Double(category.count) / Double(stats.waitingItems.count), color: color, height: 4)
                                    .accessibilityHidden(true)
                            }
                            Text(String(format: appLanguage.text("%d 件"), category.count))
                                .font(.system(size: 12).monospacedDigit()).foregroundStyle(HWTheme.secondaryText).fixedSize()
                            Image(systemName: "chevron.right").font(.system(size: 9, weight: .medium)).foregroundStyle(HWTheme.tertiaryText)
                        }.frame(minHeight: 36).contentShape(Rectangle())
                    }.buttonStyle(.plain)
                }
            }
        }.padding(14).botanicalCard()
    }

    private func recentItems(_ stats: WishStatistics) -> some View {
        let recent = stats.activeItems.sorted { $0.createdAt > $1.createdAt }.prefix(6)
        return VStack(alignment: .leading, spacing: 8) {
            sectionHeader("最近添加") { onOpenWishList(nil) }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 10) {
                    ForEach(Array(recent)) { item in
                        Button { openURL(WishDeepLink.wish(item.id).url) } label: {
                            VStack(alignment: .leading, spacing: 7) {
                                WishPhoto(data: item.photoData, width: 104, height: 84, fallbackIcon: "bag")
                                Text(item.title).font(.caption.weight(.medium)).lineLimit(1)
                                    .foregroundStyle(HWTheme.primaryText)
                            }.padding(8).frame(width: 120)
                                .background(HWTheme.cardBackground.opacity(0.9), in: RoundedRectangle(cornerRadius: 14))
                        }.buttonStyle(.plain)
                    }
                }
            }
        }.padding(.horizontal, 2)
    }

    private func sectionHeader(_ title: String, action: @escaping () -> Void) -> some View {
        HStack {
            sectionTitle(title)
            Spacer(minLength: 8)
            Button(action: action) {
                HStack(spacing: 6) {
                    Text(appLanguage.text("查看全部"))
                    Image(systemName: "chevron.right").font(.system(size: 10, weight: .medium))
                }.font(.caption).foregroundStyle(HWTheme.secondaryText)
                    .frame(minHeight: 30).contentShape(Rectangle())
            }.buttonStyle(.plain)
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
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(HWTheme.primaryText)
    }

    private func statusColor(_ status: WishItemStatus) -> Color {
        switch status {
        case .waiting: return HWTheme.freshGreen
        case .bought: return Color(red: 0.19, green: 0.49, blue: 0.74)
        case .released: return HWTheme.dangerRed
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
        let colors = [HWTheme.freshGreen, Color(red: 0.32, green: 0.62, blue: 0.85), HWTheme.blossom, HWTheme.softWood]
        return colors[index % colors.count]
    }

    private func categoryIcon(_ category: String) -> String {
        let value = category.lowercased()
        if value.contains("数码") || value.contains("apple") || value.contains("电子") { return "iphone" }
        if value.contains("衣") || value.contains("服饰") || value.contains("鞋") { return "tshirt" }
        if value.contains("汽车") || value.contains("car") { return "car" }
        if value.contains("家居") || value.contains("生活") { return "house" }
        if value.contains("rolex") || value.contains("表") { return "watch.analog" }
        if value.contains("hermès") || value.contains("vuitton") || value.contains("包") { return "bag" }
        if value.contains("书") { return "book.closed" }
        if value.contains("礼物") { return "gift" }
        if value.contains("运动") { return "figure.run" }
        return "tag"
    }

    private func moneyText(_ value: Double, code: String) -> String {
        WishCurrency.format(value, code: code)
    }
}

private extension View {
    func botanicalCard(cornerRadius: CGFloat = 18) -> some View {
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

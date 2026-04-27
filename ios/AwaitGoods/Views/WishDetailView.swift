import SwiftData
import SwiftUI
import UIKit

struct WishDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.modelContext) private var modelContext

    let item: WishItem
    let onChange: () -> Void

    @State private var showingEditor = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .top, spacing: 10) {
                            Text(item.title)
                                .font(.system(size: 24, weight: .medium))
                                .foregroundStyle(HWTheme.primaryText)
                                .lineLimit(3)

                            Spacer()

                            StatusBadge(status: item.status)
                        }

                        HStack(spacing: 7) {
                            if let priceText {
                                infoPill(priceText, color: HWTheme.freshGreen)
                            }

                            if !item.category.isEmpty {
                                infoPill(item.category, color: HWTheme.softBlueGray)
                            }

                            infoPill("\(item.priority.title)优先级", color: HWTheme.softWood)
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(HWTheme.cardBackground)
                    )
                    .overlay(markStripe, alignment: .leading)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(HWTheme.cardBorder.opacity(0.55))
                    )
                    .shadow(color: HWTheme.softShadow, radius: 8, x: 0, y: 4)

                    detailSection("等待") {
                        detailRow(title: "已等待", value: waitedDaysText)
                        detailRow(title: "决定时间", value: waitDecisionText)
                        if let targetDate = item.targetDate {
                            detailRow(title: "目标日期", value: targetDate.formatted(date: .abbreviated, time: .omitted))
                        }

                        Text(decisionText)
                            .font(.system(size: 14))
                            .foregroundStyle(HWTheme.secondaryText)
                            .padding(.top, 4)
                    }

                    if item.linkURL != nil || !item.note.isEmpty {
                        detailSection("记录") {
                            if let url = item.linkURL {
                                Button { openURL(url) } label: {
                                    HStack {
                                        Label("打开商品页面", systemImage: "safari")
                                        Spacer()
                                    }
                                }
                                .foregroundStyle(HWTheme.linkBlue)
                            }

                            if !item.note.isEmpty {
                                HStack {
                                    Text(item.note)
                                        .font(.system(size: 15))
                                        .foregroundStyle(HWTheme.primaryText)
                                    Spacer()
                                }
                            }
                        }
                    }

                    detailSection("现在怎么处理") {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            statusAction("已买", icon: WishItemStatus.bought.iconName, status: .bought, color: HWTheme.softBlueGray)
                            statusAction("想买", icon: WishItemStatus.waiting.iconName, status: .waiting, color: HWTheme.freshGreen)
                            statusAction("不买", icon: WishItemStatus.released.iconName, status: .released, color: HWTheme.tertiaryText)
                            statusAction("再想想", icon: WishItemStatus.paused.iconName, status: .paused, color: HWTheme.softWood)
                        }
                    }
                }
                .padding(14)
            }
            .background(HWTheme.pageBackground.ignoresSafeArea())
            .navigationTitle("详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("返回") { dismiss() }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("编辑") { showingEditor = true }
                        .foregroundStyle(HWTheme.weChatGreen)
                }
            }
            .sheet(isPresented: $showingEditor) {
                WishEditorView(item: item, existingItems: [item]) { savedItem in
                    try? modelContext.save()
                    onChange()
                    Task { await NotificationScheduler.schedule(for: savedItem) }
                }
            }
        }
    }

    private var markBackground: Color {
        item.markColor == .none ? HWTheme.cardBackground : HWTheme.markColor(item.markColor)
    }

    @ViewBuilder
    private var markStripe: some View {
        if item.markColor != .none {
            HStack(spacing: 0) {
                Rectangle()
                    .fill(HWTheme.markColor(item.markColor))
                    .frame(width: 3)
                Spacer()
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private var priceText: String? {
        guard let price = item.price else { return nil }
        return "¥\(price.formatted(.number.precision(.fractionLength(0...2))))"
    }

    private var waitedDaysText: String {
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: item.createdAt), to: Calendar.current.startOfDay(for: Date())).day ?? 0
        return "\(max(days, 0)) 天"
    }

    private var waitDecisionText: String {
        guard let waitUntil = item.waitUntil else { return "未设置" }
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: Calendar.current.startOfDay(for: waitUntil)).day ?? 0
        if days > 0 { return "还要等 \(days) 天" }
        if days == 0 { return "今天可以决定" }
        return "已经可以再看看"
    }

    private var decisionText: String {
        switch item.status {
        case .waiting:
            return item.waitUntil.map { $0 <= Date() ? "等待结束了，看看它是否仍然值得。" : "还想要，就让它再等一天。" } ?? "先放在这里，别急着决定。"
        case .bought:
            return "已经买了，记得回看它是否真的被使用。"
        case .released:
            return "不买也很好，清单因此更轻。"
        case .paused:
            return "先再想想，等需求自己变清楚。"
        }
    }

    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(HWTheme.secondaryText)
            Spacer()
            Text(value)
                .foregroundStyle(HWTheme.primaryText)
        }
        .font(.system(size: 15))
    }

    private func detailSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(HWTheme.primaryText)

            content()
        }
        .softCard()
    }

    private func infoPill(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .regular))
            .foregroundStyle(color)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(HWTheme.fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func statusAction(_ title: String, icon: String, status: WishItemStatus, color: Color) -> some View {
        let isSelected = status == item.status
        return Button { updateStatus(status) } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .regular))

                Text(title)
                    .font(.system(size: 14, weight: isSelected ? .medium : .regular))
            }
            .foregroundStyle(isSelected ? HWTheme.freshGreen : HWTheme.secondaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? HWTheme.mint.opacity(0.24) : HWTheme.fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func updateStatus(_ status: WishItemStatus) {
        item.status = status
        try? modelContext.save()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        onChange()

        Task {
            if status == .waiting {
                await NotificationScheduler.schedule(for: item)
            } else {
                await NotificationScheduler.cancel(for: item)
            }
        }
    }
}

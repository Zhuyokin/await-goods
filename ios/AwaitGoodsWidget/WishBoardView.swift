import SwiftUI
import WidgetKit

struct WishBoardView: View {
    let entry: WishBoardEntry
    private var copy: WidgetCopy { WidgetCopy(languageCode: entry.languageCode) }
    private var pricedItems: [WishSnapshot] { entry.items.filter { ($0.price ?? 0) > 0 } }
    private var target: Double { pricedItems.reduce(0) { $0 + ($1.price ?? 0) } }
    private var saved: Double { pricedItems.reduce(0) { $0 + min(max($1.savedAmount, 0), $1.price ?? 0) } }

    var body: some View {
        GeometryReader { geometry in
            let wide = geometry.size.width > geometry.size.height * 1.2
            let tall = geometry.size.height > 500
            let queueLimit = geometry.size.height > 650 ? 3 : 2
            let rowCount = min(max(entry.items.count - 1, 0), queueLimit)
            let queueHeight = rowCount > 0 ? CGFloat(14 + rowCount * 52) : 0
            let photoHeight = max(0, min(160, geometry.size.height - queueHeight - 420))
            VStack(alignment: .leading, spacing: tall ? 14 : 8) {
                header
                if let item = entry.focus {
                    if wide {
                        HStack(alignment: .top, spacing: 16) {
                            focusCard(item, photoHeight: 0)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            VStack(alignment: .leading, spacing: 12) {
                                overview
                                queue(limit: geometry.size.height > 360 ? 3 : 2)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    } else {
                        if tall { overview }
                        focusCard(item, photoHeight: tall ? photoHeight : 0)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        if tall { queue(limit: queueLimit) }
                    }
                } else {
                    emptyState
                }
                footer
            }
            .foregroundStyle(WidgetPalette.ink)
        }
        .containerBackground(for: .widget) { WidgetPalette.backgroundGradient }
        .widgetURL(WishDeepLink.home.url)
    }

    private var header: some View {
        HStack(spacing: 8) {
            WidgetImages.appIcon.resizable().frame(width: 22, height: 22)
                .clipShape(RoundedRectangle(cornerRadius: 5))
            VStack(alignment: .leading, spacing: 2) {
                Text(copy.localized("心愿看板", "心願看板", "Wish board"))
                    .font(.system(size: 16, weight: .semibold))
                Text(copy.waitingSummary(count: entry.items.count))
                    .font(.system(size: 10)).foregroundStyle(WidgetPalette.secondary)
            }
            Spacer(minLength: 4)
            Link(destination: WishDeepLink.add.url) {
                Image(systemName: "plus").font(.system(size: 17, weight: .medium))
                    .frame(width: 44, height: 44)
                    .background(WidgetPalette.field, in: Circle())
            }
            .accessibilityLabel(copy.localized("新增心愿", "新增心願", "Add a wish"))
        }
    }

    private var overview: some View {
        HStack(spacing: 12) {
            metric(copy.savedLabel, value: money(saved))
            Rectangle().fill(WidgetPalette.separator).frame(width: 1, height: 28)
            metric(copy.localized("还需储蓄", "還需儲蓄", "Still to save"), value: money(max(target - saved, 0)))
        }
        .padding(.horizontal, 4)
        .accessibilityElement(children: .combine)
    }

    private func metric(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 10)).foregroundStyle(WidgetPalette.secondary)
            Text(value).font(.system(size: 23, weight: .semibold, design: .rounded).monospacedDigit())
                .lineLimit(1).minimumScaleFactor(0.6).foregroundStyle(WidgetPalette.green)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func focusCard(_ item: WishSnapshot, photoHeight: CGFloat) -> some View {
        let compact = photoHeight == 0
        return VStack(alignment: .leading, spacing: compact ? 6 : 10) {
            Link(destination: WishDeepLink.wish(item.id).url) {
                VStack(alignment: .leading, spacing: 10) {
                    if photoHeight > 0 {
                        WidgetProductPhoto(item: item)
                            .frame(maxWidth: .infinity).frame(height: photoHeight)
                    }
                    HStack(spacing: 10) {
                        if compact { WidgetProductPhoto(item: item).frame(width: 44, height: 44) }
                        VStack(alignment: .leading, spacing: 5) {
                            Text(item.title).font(.system(size: compact ? 17 : 19, weight: .semibold, design: .rounded))
                                .lineLimit(compact ? 1 : 2).minimumScaleFactor(0.8)
                            timing(item)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "arrow.up.right").font(.system(size: 11, weight: .medium))
                            .foregroundStyle(WidgetPalette.secondary)
                    }
                }
                .contentShape(Rectangle())
            }
            Spacer(minLength: 0)
            savings(item, compact: compact)
            actions(item)
        }
        .padding(compact ? 10 : 12)
        .background(WidgetPalette.card, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(WidgetPalette.separator.opacity(0.5)))
    }

    @ViewBuilder
    private func timing(_ item: WishSnapshot) -> some View {
        if let date = item.waitUntil {
            let cooling = date > entry.date
            Label {
                if cooling {
                    let days = Int(ceil(date.timeIntervalSince(entry.date) / 86400))
                    Text(copy.localized("冷静期 · 还剩 \(days) 天", "冷靜期 · 還剩 \(days) 天", "Cooling off · \(days)d left"))
                } else {
                    Text(copy.localized("冷静期已结束", "冷靜期已結束", "Ready to decide"))
                }
            } icon: { Image(systemName: cooling ? "hourglass" : "checkmark.circle") }
            .font(.system(size: 11)).foregroundStyle(WidgetPalette.green)
            .lineLimit(1).minimumScaleFactor(0.7)
        } else if let date = item.targetDate {
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                Text(date, style: .date)
            }
            .font(.system(size: 11)).foregroundStyle(WidgetPalette.secondary).lineLimit(1)
        } else {
            Text(copy.localized("让心愿一点点靠近", "讓心願一點點靠近", "A little closer, every day"))
                .font(.system(size: 11)).foregroundStyle(WidgetPalette.secondary).lineLimit(1)
        }
    }

    private func savings(_ item: WishSnapshot, compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(copy.savedLabel) \(money(item.savedAmount))")
                    .font(.system(size: 14, weight: .semibold).monospacedDigit())
                Spacer(minLength: 4)
                Text(item.remainingAmount == nil ? "—" : "\(Int((item.savingsProgress * 100).rounded()))%")
                    .font(.system(size: 12, weight: .medium).monospacedDigit())
            }
            .foregroundStyle(WidgetPalette.green).lineLimit(1).minimumScaleFactor(0.7)
            GeometryReader { geometry in
                Capsule().fill(WidgetPalette.field)
                    .overlay(alignment: .leading) {
                        Capsule().fill(WidgetPalette.green)
                            .frame(width: geometry.size.width * item.savingsProgress)
                            .widgetAccentable()
                    }
            }
            .frame(height: 5)
            if !compact, let remaining = item.remainingAmount {
                Text(copy.remainingText(money(remaining)))
                    .font(.system(size: 10)).foregroundStyle(WidgetPalette.secondary)
            }
        }
        .invalidatableContent()
        .accessibilityElement(children: .combine)
    }

    private func actions(_ item: WishSnapshot) -> some View {
        HStack(spacing: 6) {
            if item.updatedAt != nil, let remaining = item.remainingAmount, remaining > 0 {
                let amount = min(entry.depositAmount, remaining)
                Button(intent: RecordWishSavingsIntent(item: item, amount: amount, scope: entry.scope)) {
                    Label(copy.localized("记一笔 \(money(amount))", "記一筆 \(money(amount))", "Save \(money(amount))"), systemImage: "plus")
                        .font(.system(size: 13, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(WidgetPalette.green.opacity(0.16), in: Capsule())
                }
                .buttonStyle(.plain).foregroundStyle(WidgetPalette.green)
            } else {
                Link(destination: WishDeepLink.wish(item.id).url) {
                    Text(copy.localized("查看心愿", "查看心願", "View wish"))
                        .font(.system(size: 13, weight: .semibold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(WidgetPalette.field, in: Capsule())
                }
            }
            if entry.items.count > 1 {
                navigationButton(direction: -1, symbol: "chevron.left")
                navigationButton(direction: 1, symbol: "chevron.right")
            }
        }
    }

    @ViewBuilder
    private func navigationButton(direction: Int, symbol: String) -> some View {
        if let id = WishBoardSelection.next(in: entry.items, currentID: entry.focus?.id, direction: direction) {
            Button(intent: SelectBoardWishIntent(id: id, scope: entry.scope)) {
                Image(systemName: symbol).font(.system(size: 13, weight: .semibold))
                    .frame(width: 44, height: 44).background(WidgetPalette.field, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(direction < 0 ? copy.localized("上一个心愿", "上一個心願", "Previous wish") : copy.localized("下一个心愿", "下一個心願", "Next wish"))
        }
    }

    private func queue(limit: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if entry.items.count > 1 {
                Text(copy.localized("心愿清单", "心願清單", "On your list"))
                    .font(.system(size: 11, weight: .medium)).foregroundStyle(WidgetPalette.secondary)
                ForEach(Array(entry.items.filter { $0.id != entry.focus?.id }.prefix(limit))) { item in
                    Button(intent: SelectBoardWishIntent(id: item.id, scope: entry.scope)) {
                        HStack(spacing: 10) {
                            WidgetProductPhoto(item: item).frame(width: 36, height: 36)
                            Text(item.title).font(.system(size: 12, weight: .medium)).lineLimit(1)
                            Spacer(minLength: 0)
                            Text(item.remainingAmount == nil ? "—" : "\(Int((item.savingsProgress * 100).rounded()))%")
                                .font(.system(size: 11).monospacedDigit()).foregroundStyle(WidgetPalette.green)
                        }
                        .padding(.horizontal, 10).frame(minHeight: 46)
                        .background(WidgetPalette.card.opacity(0.7), in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(copy.localized("切换到 \(item.title)", "切換到 \(item.title)", "Focus on \(item.title)"))
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Spacer(minLength: 0)
            Image(systemName: "sparkles").font(.system(size: 36)).foregroundStyle(WidgetPalette.green)
            Text(copy.emptyTitle).font(.system(size: 24, weight: .semibold, design: .rounded))
            Text(copy.emptySubtitle).font(.system(size: 13)).foregroundStyle(WidgetPalette.secondary)
            Link(destination: WishDeepLink.add.url) {
                Label(copy.localized("记下一个心愿", "記下一個心願", "Add your next wish"), systemImage: "plus")
                    .font(.system(size: 14, weight: .semibold)).padding(.vertical, 12)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var footer: some View {
        if let feedback = entry.feedback {
            HStack(spacing: 8) {
                Text(feedbackText(feedback)).lineLimit(1).minimumScaleFactor(0.7)
                Spacer(minLength: 0)
                if feedback.outcome == .saved, let receipt = feedback.receipt {
                    Button(intent: UndoWishSavingsIntent(receiptID: receipt.id, scope: entry.scope)) {
                        Text(copy.localized("撤销", "撤銷", "Undo"))
                            .fontWeight(.semibold).frame(minWidth: 44, minHeight: 44)
                    }
                    .buttonStyle(.plain).foregroundStyle(WidgetPalette.green)
                }
            }
            .font(.system(size: 11)).foregroundStyle(WidgetPalette.secondary)
        } else {
            Link(destination: WishDeepLink.home.url) {
                HStack {
                    Text(copy.localized("先心动，再从容拥有。", "先心動，再從容擁有。", "Wish today. Make it yours in time."))
                    Spacer(minLength: 4)
                    Image(systemName: "arrow.right")
                }
                .font(.system(size: 10)).foregroundStyle(WidgetPalette.secondary)
            }
        }
    }

    private func feedbackText(_ feedback: WishBoardFeedback) -> String {
        switch feedback.outcome {
        case .saved:
            guard let receipt = feedback.receipt else { return "" }
            return copy.localized("已记 \(money(receipt.amount)) · \(receipt.title)", "已記 \(money(receipt.amount)) · \(receipt.title)", "Saved \(money(receipt.amount)) · \(receipt.title)")
        case .undone: return copy.localized("已撤销这笔记录", "已撤銷這筆記錄", "Entry undone")
        case .stale: return copy.localized("心愿已变化，请按最新内容操作", "心願已變化，請按最新內容操作", "Wish updated. Please try again.")
        case .failed: return copy.localized("未能保存，请打开 App 重试", "未能儲存，請打開 App 重試", "Couldn’t save. Open the app to retry.")
        }
    }

    private func money(_ amount: Double) -> String {
        "$\(amount.formatted(.number.precision(.fractionLength(0...2))))"
    }
}

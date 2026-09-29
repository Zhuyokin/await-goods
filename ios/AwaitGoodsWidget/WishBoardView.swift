import SwiftUI
import WidgetKit

struct WishBoardView: View {
    @Environment(\.colorScheme) private var colorScheme
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
            let extraHeight = tall && !wide ? 57 + (queueHeight > 0 ? queueHeight + 8 : 0) : 0
            let photoHeight = max(0, geometry.size.height - extraHeight - 284)
            VStack(alignment: .leading, spacing: 8) {
                header
                if let item = entry.focus {
                    if wide {
                        HStack(alignment: .top, spacing: 16) {
                            focusCard(item, photoHeight: photoHeight)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            VStack(alignment: .leading, spacing: 12) {
                                overview
                                queue(limit: geometry.size.height > 360 ? 3 : 2)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    } else {
                        if tall { overview }
                        focusCard(item, photoHeight: photoHeight)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        if tall, rowCount > 0 { queue(limit: queueLimit) }
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
                Text("\(entry.currencyCode) · \(copy.waitingSummary(count: entry.items.count))")
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
        let compact = photoHeight < 24
        return VStack(alignment: .leading, spacing: 6) {
            Link(destination: WishDeepLink.wish(item.id).url) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 10) {
                        if compact { WidgetProductPhoto(item: item).frame(width: 44, height: 44) }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.title).font(.system(size: 18, weight: .semibold, design: .rounded))
                                .lineLimit(1).minimumScaleFactor(0.8)
                            timing(item)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "arrow.up.right").font(.system(size: 11, weight: .medium))
                            .foregroundStyle(WidgetPalette.secondary)
                    }
                    if !compact {
                        WidgetProductPhoto(item: item)
                            .frame(maxWidth: .infinity).frame(height: photoHeight)
                    }
                }
                .contentShape(Rectangle())
            }
            savings(item, compact: compact)
            actions(item)
        }
        .padding(10)
        .background(WidgetPalette.card, in: RoundedRectangle(cornerRadius: 20))
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
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(copy.savedLabel)
                    .font(.system(size: 11)).foregroundStyle(WidgetPalette.secondary)
                Text(money(item.savedAmount))
                    .font(.system(size: compact ? 23 : 24, weight: .semibold, design: .rounded).monospacedDigit())
                    .foregroundStyle(WidgetPalette.ink)
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
            if let target = item.price, let remaining = item.remainingAmount {
                HStack(spacing: 4) {
                    Text("\(copy.targetLabel) \(money(target))")
                    Spacer(minLength: 0)
                    Text(copy.remainingText(money(remaining)))
                }
                .font(.system(size: 10).monospacedDigit()).foregroundStyle(WidgetPalette.secondary)
                .lineLimit(1).minimumScaleFactor(0.7)
            }
        }
        .invalidatableContent()
        .accessibilityElement(children: .combine)
    }

    private func actions(_ item: WishSnapshot) -> some View {
        let canDeposit = (item.remainingAmount ?? 0) > 0
        return Link(destination: canDeposit ? WishDeepLink.deposit(item.id).url : WishDeepLink.wish(item.id).url) {
            HStack(spacing: 8) {
                Spacer(minLength: 0)
                if canDeposit { Image(systemName: "plus") }
                Text(canDeposit ? copy.localized("记一笔", "記一筆", "Add savings") : copy.localized("查看心愿", "查看心願", "View wish"))
                Spacer(minLength: 0)
            }
            .overlay(alignment: .trailing) {
                Image(systemName: "arrow.up.right").font(.system(size: 12, weight: .semibold))
            }
            .font(.system(size: 14, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.7)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 44)
            .foregroundStyle(canDeposit ? (colorScheme == .dark ? WidgetPalette.background : .white) : WidgetPalette.ink)
            .background(canDeposit ? WidgetPalette.green : WidgetPalette.field, in: Capsule())
        }
    }

    @ViewBuilder
    private func navigationButton(direction: Int, symbol: String) -> some View {
        if let id = WishBoardSelection.next(in: entry.items, currentID: entry.focus?.id, direction: direction) {
            Button(intent: SelectBoardWishIntent(id: id, scope: entry.scope)) {
                Image(systemName: symbol).font(.system(size: 13, weight: .semibold))
                    .frame(width: 44, height: 44)
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
            Text(copy.emptyCurrencySubtitle(entry.currencyCode)).font(.system(size: 13)).foregroundStyle(WidgetPalette.secondary)
            Link(destination: WishDeepLink.add.url) {
                Label(copy.localized("记下一个心愿", "記下一個心願", "Add your next wish"), systemImage: "plus")
                    .font(.system(size: 14, weight: .semibold)).padding(.vertical, 12)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var footer: some View {
        HStack(spacing: 0) {
            if let feedback = entry.feedback {
                Text(feedbackText(feedback)).font(.system(size: 10))
                    .foregroundStyle(WidgetPalette.secondary).lineLimit(1).minimumScaleFactor(0.7)
                if feedback.outcome == .saved, let receipt = feedback.receipt {
                    Button(intent: UndoWishSavingsIntent(receiptID: receipt.id, scope: entry.scope)) {
                        Text(copy.localized("撤销", "撤銷", "Undo"))
                            .font(.system(size: 11, weight: .semibold)).frame(minWidth: 44, minHeight: 44)
                    }
                    .buttonStyle(.plain).foregroundStyle(WidgetPalette.green)
                }
            } else {
                Link(destination: WishDeepLink.home.url) {
                    Text(copy.localized("先心动，再从容拥有。", "先心動，再從容擁有。", "Wish today. Make it yours in time."))
                        .font(.system(size: 10)).foregroundStyle(WidgetPalette.secondary)
                        .lineLimit(1).minimumScaleFactor(0.7)
                }
            }
            Spacer(minLength: 4)
            if entry.items.count > 1 {
                navigationButton(direction: -1, symbol: "chevron.left")
                Text("\((entry.items.firstIndex { $0.id == entry.focus?.id } ?? 0) + 1) / \(entry.items.count)")
                    .font(.system(size: 10, weight: .medium).monospacedDigit())
                    .foregroundStyle(WidgetPalette.secondary).fixedSize()
                navigationButton(direction: 1, symbol: "chevron.right")
            }
        }
        .frame(minHeight: 44)
    }

    private func feedbackText(_ feedback: WishBoardFeedback) -> String {
        switch feedback.outcome {
        case .saved:
            guard let receipt = feedback.receipt else { return "" }
            let amount = WishCurrency.format(receipt.amount, code: receipt.currencyCode ?? "USD")
            return copy.localized("已记 \(amount) · \(receipt.title)", "已記 \(amount) · \(receipt.title)", "Saved \(amount) · \(receipt.title)")
        case .undone: return copy.localized("已撤销这笔记录", "已撤銷這筆記錄", "Entry undone")
        case .stale: return copy.localized("心愿已变化，请按最新内容操作", "心願已變化，請按最新內容操作", "Wish updated. Please try again.")
        case .failed: return copy.localized("未能保存，请打开 App 重试", "未能儲存，請打開 App 重試", "Couldn’t save. Open the app to retry.")
        }
    }

    private func money(_ amount: Double) -> String {
        WishCurrency.format(amount, code: entry.currencyCode)
    }
}

import SwiftData
import SwiftUI
import UIKit

struct WishDetailView: View {
    @Environment(\.appLanguage) private var appLanguage
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.modelContext) private var modelContext

    let item: WishItem
    let onChange: () -> Void

    @State private var isEditing = false
    @State private var depositText = ""

    var body: some View {
        NavigationStack {
            if isEditing {
                WishEditorView(
                    item: item,
                    existingItems: [item],
                    embedsInNavigationStack: false,
                    dismissOnSave: false,
                    onCancel: { isEditing = false }
                ) { _ in
                    persistChanges()
                    isEditing = false
                }
            } else {
                detailContent
            }
        }
    }

    private var detailContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                headerCard
                savingsSection

                if item.linkURL != nil || !item.note.isEmpty {
                    recordSection
                }

                detailSection(appLanguage.text("现在怎么处理")) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        statusAction(appLanguage.text(WishItemStatus.bought.title), icon: WishItemStatus.bought.iconName, status: .bought)
                        statusAction(appLanguage.text(WishItemStatus.waiting.title), icon: WishItemStatus.waiting.iconName, status: .waiting)
                        statusAction(appLanguage.text(WishItemStatus.released.title), icon: WishItemStatus.released.iconName, status: .released)
                    }
                }
            }
            .padding(14)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(HWTheme.pageBackground.ignoresSafeArea())
        .navigationTitle(appLanguage.text("详情"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(appLanguage.text("返回")) { dismiss() }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button(appLanguage.text("编辑")) { isEditing = true }
                    .foregroundStyle(HWTheme.weChatGreen)
            }
        }
    }

    private var headerCard: some View {
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

                infoPill(appLanguage.text(item.priority.title) + appLanguage.text("优先级"), color: HWTheme.softWood)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(HWTheme.cardBackground)
        )
        .overlay(markStripe, alignment: .leading)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(HWTheme.cardBorder.opacity(0.55))
        )
        .shadow(color: HWTheme.softShadow, radius: 3, x: 0, y: 1)
    }

    private var savingsSection: some View {
        detailSection(appLanguage.text("存钱")) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(savingsTitle)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(HWTheme.primaryText)

                    Spacer()

                    if item.savingsTarget != nil {
                        Text("\(Int((item.savingsProgress * 100).rounded()))%")
                            .font(.system(size: 13, weight: .regular).monospacedDigit())
                            .foregroundStyle(HWTheme.secondaryText)
                    }
                }

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(HWTheme.fieldBackground)

                        Capsule()
                            .fill(item.isSavingsComplete ? HWTheme.softBlueGray : HWTheme.freshGreen.opacity(0.72))
                            .frame(width: proxy.size.width * item.savingsProgress)
                    }
                }
                .frame(height: 7)

                if let target = item.savingsTarget {
                    detailRow(title: appLanguage.text("目标"), value: moneyText(target))
                    detailRow(title: appLanguage.text("已存"), value: moneyText(item.savedAmountValue))
                    detailRow(title: appLanguage.text("还差"), value: moneyText(item.remainingSavingsAmount ?? 0))
                } else {
                    detailRow(title: appLanguage.text("已存"), value: moneyText(item.savedAmountValue))
                    detailRow(title: appLanguage.text("目标"), value: appLanguage.text("目标未定"))
                }

                Text(decisionText)
                    .font(.system(size: 14))
                    .foregroundStyle(HWTheme.secondaryText)
                    .padding(.top, 2)

                HStack(spacing: 8) {
                    TextField(appLanguage.text("存入金额"), text: $depositText)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 15, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(HWTheme.fieldBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .disabled(item.isSavingsComplete)

                    Button(appLanguage.text("存入")) { addDeposit() }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(HWTheme.cardBackground)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 10)
                        .background(parsedDeposit == nil ? HWTheme.tertiaryText.opacity(0.72) : HWTheme.freshGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .disabled(parsedDeposit == nil)

                    if canFillSavings {
                        Button(appLanguage.text("补满")) { fillSavings() }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(HWTheme.freshGreen)
                            .padding(.horizontal, 13)
                            .padding(.vertical, 10)
                            .background(HWTheme.mint.opacity(0.22))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }

                if let depositValidationMessage {
                    Text(depositValidationMessage)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(HWTheme.dangerRed)
                }
            }
        }
    }

    private var recordSection: some View {
        detailSection(appLanguage.text("记录")) {
            if let url = item.linkURL {
                Button { openURL(url) } label: {
                    HStack {
                        Label(appLanguage.text("打开商品页面"), systemImage: "safari")
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

    @ViewBuilder
    private var markStripe: some View {
        if item.markColor != .none {
            HStack(spacing: 0) {
                Rectangle()
                    .fill(HWTheme.markColor(item.markColor))
                    .frame(width: 3)
                Spacer()
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var priceText: String? {
        guard let price = item.price else { return nil }
        return moneyText(price)
    }

    private var savingsTitle: String {
        if item.isSavingsComplete { return appLanguage.text("已存满") }
        guard let remaining = item.remainingSavingsAmount else { return appLanguage.text("目标未定") }
        return "\(appLanguage.text("还差")) \(moneyText(remaining))"
    }

    private var decisionText: String {
        switch item.status {
        case .waiting:
            return item.savingsTarget == nil ? appLanguage.text("先留在清单里，让预算慢慢清楚。") : appLanguage.text("一点点存起来，心愿会变得更踏实。")
        case .bought:
            return appLanguage.text("已经拥有，记得回看它是否真的被使用。")
        case .released:
            return appLanguage.text("放下也很好，清单因此更轻。")
        }
    }

    private var parsedDeposit: Double? {
        guard !item.isSavingsComplete else { return nil }
        guard let amount = normalizedAmount(from: depositText) else { return nil }
        if let remaining = item.remainingSavingsAmount, amount > remaining { return nil }
        return amount
    }

    private var depositValidationMessage: String? {
        let hasDeposit = !depositText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        guard hasDeposit else { return nil }
        if item.isSavingsComplete { return appLanguage.text("已经存满，不需要继续存入") }
        guard let amount = normalizedAmount(from: depositText) else { return appLanguage.text("存入金额需大于 0") }
        if let remaining = item.remainingSavingsAmount, amount > remaining { return appLanguage.text("本次存入不能超过还差金额") }
        return nil
    }

    private var canFillSavings: Bool {
        guard let remaining = item.remainingSavingsAmount else { return false }
        return remaining > 0
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

    private func statusAction(_ title: String, icon: String, status: WishItemStatus) -> some View {
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
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func addDeposit() {
        guard let parsedDeposit else { return }
        item.savedAmountValue += parsedDeposit
        item.reconcileSavingsStatus()
        depositText = ""
        persistChanges()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func fillSavings() {
        guard let target = item.savingsTarget else { return }
        item.savedAmountValue = target
        item.reconcileSavingsStatus()
        persistChanges()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func updateStatus(_ status: WishItemStatus) {
        item.status = status
        persistChanges()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func persistChanges() {
        try? modelContext.save()
        onChange()
    }

    private func normalizedAmount(from text: String) -> Double? {
        let normalized = text
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Double(normalized), value > 0 else { return nil }
        return value
    }

    private func moneyText(_ value: Double) -> String {
        "$\(value.formatted(.number.precision(.fractionLength(0...0))))"
    }
}
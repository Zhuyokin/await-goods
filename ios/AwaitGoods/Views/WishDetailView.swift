import SwiftData
import SwiftUI
import UIKit

struct WishDetailView: View {
    @Environment(\.appLanguage) private var appLanguage
    @Environment(\.openURL) private var openURL
    @Environment(\.modelContext) private var modelContext

    let item: WishItem
    var focusDeposit = false
    let onEdit: () -> Void
    let onChange: () -> Void

    @State private var depositText = ""
    @State private var changeEffect: WishChangeEffect?
    @State private var changeEffectToken = UUID()
    @State private var didFocusDeposit = false
    @FocusState private var isDepositFocused: Bool

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    savingsSection
                        .id("savings")
                    if item.linkURL != nil || !item.note.isEmpty {
                        recordSection
                    }
                    statusSelector
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 24)
                .frame(maxWidth: 660)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
            .task {
                guard focusDeposit, !didFocusDeposit, !item.isSavingsComplete else { return }
                didFocusDeposit = true
                proxy.scrollTo("savings", anchor: .top)
                isDepositFocused = true
            }
        }
        .background { IllustrationBackdrop() }
        .overlay { changeEffectOverlay }
        .navigationTitle(appLanguage.text("心愿详情"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(HWTheme.pageBackground, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(appLanguage.text("编辑"), action: onEdit)
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(appLanguage.text("完成")) { isDepositFocused = false }
            }
        }
        .tint(HWTheme.freshGreen)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 18) {
            if let data = item.photoData, let photo = UIImage(data: data) {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFit()
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .frame(height: 242)
                    .background(HWTheme.cream.opacity(0.65), in: RoundedRectangle(cornerRadius: 24))
                    .accessibilityLabel(item.title)
                    .overlay(alignment: .topTrailing) {
                        StatusBadge(status: item.status).padding(14)
                    }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 12) {
                    Text(item.title)
                        .font(.system(size: 27, weight: .semibold))
                        .foregroundStyle(HWTheme.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if item.photoData == nil {
                        StatusBadge(status: item.status)
                    }
                }
                HStack(spacing: 10) {
                    if item.markColor != .none {
                        Circle().fill(HWTheme.markColor(item.markColor)).frame(width: 8, height: 8)
                            .accessibilityLabel(appLanguage.text(item.markColor.title))
                    }
                    if !item.category.isEmpty {
                        Text(appLanguage.text(item.category))
                            .foregroundStyle(HWTheme.secondaryText)
                        Circle().fill(HWTheme.tertiaryText).frame(width: 3, height: 3)
                            .accessibilityHidden(true)
                    }
                    Label(String(format: appLanguage.text("%@优先级"), appLanguage.text(item.priority.title)), systemImage: "flag.fill")
                        .foregroundStyle(HWTheme.softWood)
                }
                .font(.system(size: 13))
            }
        }
    }

    private var savingsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .lastTextBaseline) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(appLanguage.text("已存金额"))
                        .font(.system(size: 12))
                        .foregroundStyle(HWTheme.secondaryText)
                    Text(moneyText(item.savedAmountValue))
                        .font(.system(size: 32, weight: .semibold, design: .rounded).monospacedDigit())
                        .foregroundStyle(HWTheme.primaryText)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                if item.savingsTarget != nil {
                    Text(item.isSavingsComplete ? appLanguage.text("已存满") : "\(Int((item.savingsProgress * 100).rounded()))%")
                        .font(.system(size: 16, weight: .medium).monospacedDigit())
                        .foregroundStyle(HWTheme.freshGreen)
                }
            }

            if let target = item.savingsTarget {
                ProgressView(value: item.savingsProgress)
                    .tint(HWTheme.freshGreen)
                ViewThatFits(in: .horizontal) {
                    HStack {
                        targetLabel(target)
                        Spacer(minLength: 8)
                        remainingLabel
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        targetLabel(target)
                        remainingLabel
                    }
                }
                .font(.system(size: 12).monospacedDigit())
            } else {
                Text(appLanguage.text("目标未定"))
                    .font(.system(size: 13))
                    .foregroundStyle(HWTheme.secondaryText)
            }

            HStack(spacing: 10) {
                HStack(spacing: 7) {
                    Text("$").foregroundStyle(HWTheme.freshGreen)
                    TextField(appLanguage.text("存入金额"), text: $depositText)
                        .keyboardType(.decimalPad)
                        .focused($isDepositFocused)
                        .disabled(item.isSavingsComplete)
                }
                .padding(.horizontal, 12)
                .frame(minHeight: 44)
                .background(HWTheme.fieldBackground, in: RoundedRectangle(cornerRadius: 12))

                Button(appLanguage.text("存入"), action: addDeposit)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .frame(minHeight: 44)
                    .background(parsedDeposit == nil ? HWTheme.tertiaryText : HWTheme.freshGreen, in: RoundedRectangle(cornerRadius: 12))
                    .disabled(parsedDeposit == nil)

                if canFillSavings {
                    Button(appLanguage.text("补满"), action: fillSavings)
                        .fontWeight(.medium)
                        .foregroundStyle(HWTheme.freshGreen)
                        .frame(minWidth: 44, minHeight: 44)
                }
            }
            .font(.system(size: 15))
            .buttonStyle(.plain)

            if let depositValidationMessage {
                Text(depositValidationMessage)
                    .font(.system(size: 12))
                    .foregroundStyle(HWTheme.dangerRed)
            }
        }
        .padding(18)
        .background(HWTheme.cardBackground, in: RoundedRectangle(cornerRadius: 22))
    }

    private func targetLabel(_ target: Double) -> some View {
        Text("\(appLanguage.text("目标")) \(moneyText(target))")
            .foregroundStyle(HWTheme.secondaryText)
    }

    private var remainingLabel: some View {
        Text("\(appLanguage.text("还差")) \(moneyText(item.remainingSavingsAmount ?? 0))")
            .foregroundStyle(HWTheme.primaryText)
    }

    private var recordSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let url = item.linkURL {
                Button { openURL(url) } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "link").foregroundStyle(HWTheme.freshGreen)
                        Text(appLanguage.text("商品链接"))
                            .fontWeight(.medium)
                            .foregroundStyle(HWTheme.primaryText)
                        Spacer(minLength: 8)
                        Text(url.host?.replacingOccurrences(of: "www.", with: "") ?? "")
                            .font(.system(size: 12))
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Image(systemName: "arrow.up.right")
                    }
                    .foregroundStyle(HWTheme.secondaryText)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(appLanguage.text("打开商品页面"))
            }
            if item.linkURL != nil && !item.note.isEmpty {
                Divider().overlay(HWTheme.separator.opacity(0.4))
            }
            if !item.note.isEmpty {
                Text(item.note)
                    .lineSpacing(4)
                    .foregroundStyle(HWTheme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .font(.system(size: 14))
        .padding(18)
        .background(HWTheme.cardBackground, in: RoundedRectangle(cornerRadius: 20))
    }

    private var statusSelector: some View {
        HStack(spacing: 5) {
            ForEach(WishItemStatus.allCases) { status in
                Button { updateStatus(status) } label: {
                    Label(appLanguage.text(status.title), systemImage: status.iconName)
                        .font(.system(size: 14, weight: item.status == status ? .medium : .regular))
                        .foregroundStyle(item.status == status ? HWTheme.freshGreen : HWTheme.secondaryText)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(item.status == status ? HWTheme.mint.opacity(0.24) : .clear, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(item.status == status ? .isSelected : [])
            }
        }
        .padding(5)
        .background(HWTheme.cardBackground, in: RoundedRectangle(cornerRadius: 16))
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

    private func addDeposit() {
        guard let parsedDeposit else { return }
        let shouldMarkBought = shouldMarkBought(afterSaving: parsedDeposit)
        item.savedAmountValue += parsedDeposit
        depositText = ""
        isDepositFocused = false
        persistChanges()
        if shouldMarkBought {
            updateStatus(.bought)
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func fillSavings() {
        guard let target = item.savingsTarget else { return }
        let shouldMarkBought = item.status != .bought
        item.savedAmountValue = target
        depositText = ""
        isDepositFocused = false
        persistChanges()
        if shouldMarkBought {
            updateStatus(.bought)
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func updateStatus(_ status: WishItemStatus) {
        guard item.status != status else { return }
        showChangeEffect(.status(status))

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                item.status = status
            }
            persistChanges()
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func shouldMarkBought(afterSaving amount: Double) -> Bool {
        guard item.status != .bought, let savingsTarget = item.savingsTarget else { return false }
        return min(item.savedAmountValue + amount, savingsTarget) >= savingsTarget
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
                .transition(.scale(scale: 0.82).combined(with: .opacity))
        }
    }

    private func persistChanges() {
        try? modelContext.save()
        Task { await NotificationScheduler.schedule(for: item) }
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

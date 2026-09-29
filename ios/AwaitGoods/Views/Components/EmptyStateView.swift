import SwiftUI

enum WishListEmptyState {
    case collection, waiting, bought, released, search

    var title: String {
        switch self {
        case .collection: return "还没有心愿哦"
        case .waiting: return "新的期待，慢慢来"
        case .bought: return "美好，正在慢慢靠近"
        case .released: return "还没有放下的心愿"
        case .search: return "没有找到这份心愿"
        }
    }

    var message: String {
        switch self {
        case .collection: return "把想要的好物、旅行、礼物放进来，\n让每一份期待都有一个家。"
        case .waiting: return "暂时没有想买的物品，\n遇到心动的，再轻轻记下来。"
        case .bought: return "还没有已拥有的物品，\n心愿实现后，在这里收藏快乐。"
        case .released: return "想法改变也没关系，\n放下的心愿会安静留在这里。"
        case .search: return "试试其他名称、分类或关键词，\n也可以清空搜索再看看。"
        }
    }

    var actionTitle: String {
        switch self {
        case .collection, .waiting: return "添加心愿"
        case .bought, .released: return "查看全部心愿"
        case .search: return "清空搜索"
        }
    }

    var actionIcon: String {
        switch self {
        case .collection, .waiting: return "plus"
        case .bought, .released: return "heart"
        case .search: return "arrow.counterclockwise"
        }
    }
}

struct EmptyStateView: View {
    @Environment(\.appLanguage) private var appLanguage
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage(AppIllustratedTheme.storageKey) private var theme: AppIllustratedTheme = .sakura

    let state: WishListEmptyState
    let illustrationSize: CGFloat
    let onAction: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Image(theme.emptyStateAssetName)
                .resizable()
                .scaledToFit()
                .frame(width: illustrationSize, height: illustrationSize)
                .opacity(colorScheme == .dark ? 0.88 : 1)
                .accessibilityHidden(true)

            Text(appLanguage.text(state.title))
                .font(.title2.weight(.semibold))
                .foregroundStyle(HWTheme.primaryText)
                .padding(.top, 18)

            Text(appLanguage.text(state.message))
                .font(.subheadline)
                .lineSpacing(5)
                .foregroundStyle(HWTheme.secondaryText)
                .padding(.top, 12)

            Button(action: onAction) {
                Label(appLanguage.text(state.actionTitle), systemImage: state.actionIcon)
                    .font(.body.weight(.semibold))
                    .padding(.horizontal, 26)
                    .padding(.vertical, 14)
                    .frame(minHeight: 48)
                    .foregroundStyle(colorScheme == .dark ? HWTheme.pageBackground : .white)
                    .background(HWTheme.freshGreen, in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 26)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 28)
        .padding(.top, 24)
        .padding(.bottom, 48)
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity)
    }
}

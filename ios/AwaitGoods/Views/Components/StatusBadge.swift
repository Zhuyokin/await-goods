import SwiftUI

struct StatusBadge: View {
    @Environment(\.appLanguage) private var appLanguage

    let status: WishItemStatus

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: status.iconName)
                .font(.system(size: 10, weight: .regular))
            Text(appLanguage.text(status.title))
                .font(.system(size: 12, weight: .regular))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(HWTheme.fieldBackground)
        )
    }

    private var color: Color {
        switch status {
        case .waiting: return HWTheme.freshGreen
        case .bought: return HWTheme.softBlueGray
        case .released: return HWTheme.tertiaryText
        }
    }
}

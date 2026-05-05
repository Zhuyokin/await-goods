import SwiftUI

struct EmptyStateView: View {
    @Environment(\.appLanguage) private var appLanguage

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "bag")
                .font(.system(size: 32, weight: .ultraLight))
                .foregroundStyle(HWTheme.tertiaryText)
            .padding(.bottom, 4)

            Text(appLanguage.text("暂无候物"))
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(HWTheme.primaryText)

            Text(appLanguage.text("慢慢存，轻轻买"))
                .font(.system(size: 13))
                .foregroundStyle(HWTheme.tertiaryText)
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(HWTheme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(HWTheme.cardBorder.opacity(0.55))
        )
        .shadow(color: HWTheme.softShadow, radius: 8, x: 0, y: 4)
        .padding(.horizontal, 14)
    }
}

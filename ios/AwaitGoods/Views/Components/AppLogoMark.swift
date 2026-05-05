import SwiftUI
import UIKit

struct AppLogoMark: View {
    var size: CGFloat = 44
    var cornerRadius: CGFloat = 12

    private var appIcon: UIImage? {
        UIImage(named: "AppLogo")
    }

    var body: some View {
        Group {
            if let appIcon {
                Image(uiImage: appIcon)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "bag")
                    .font(.system(size: size * 0.45, weight: .regular))
                    .foregroundStyle(HWTheme.freshGreen)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(HWTheme.mint.opacity(0.22))
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(HWTheme.cardBorder.opacity(0.48), lineWidth: 0.8)
        )
        .shadow(color: HWTheme.softShadow, radius: 2, x: 0, y: 1)
        .accessibilityHidden(true)
    }
}
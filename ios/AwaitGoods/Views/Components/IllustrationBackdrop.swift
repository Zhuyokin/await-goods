import SwiftUI

struct IllustrationBackdrop: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage(AppIllustratedTheme.storageKey) private var theme: AppIllustratedTheme = .sakura
    var illustrationSize: CGFloat = 360

    var body: some View {
        GeometryReader { proxy in
            let topSize = min(illustrationSize, proxy.size.width * 0.92)
            let bottomSize = min(max(proxy.size.width * 0.8, 260), 440)
            LinearGradient(
                colors: [HWTheme.listBackground, HWTheme.pageBackground, HWTheme.cream],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay(alignment: .topTrailing) {
                Image(theme.topAssetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: topSize, height: topSize)
                    .opacity(colorScheme == .dark ? 0.18 : 0.48)
                    .offset(x: topSize * 0.10, y: -topSize * 0.12)
            }
            .overlay(alignment: .bottomLeading) {
                Image(theme.bottomAssetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: bottomSize, height: bottomSize)
                    .blur(radius: 1.2)
                    .opacity(colorScheme == .dark ? 0.16 : 0.48)
                    .offset(x: -bottomSize * 0.12, y: bottomSize * 0.04)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

import SwiftUI

struct IllustrationBackdrop: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage(AppBackgroundIllustration.storageKey) private var illustration: AppBackgroundIllustration = .sakura
    var illustrationSize: CGFloat = 360

    var body: some View {
        GeometryReader { proxy in
            LinearGradient(
                colors: [HWTheme.listBackground, HWTheme.pageBackground],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay(alignment: .topTrailing) {
                Image(illustration.assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: illustrationSize, height: illustrationSize)
                    .opacity(colorScheme == .dark ? 0.24 : 0.56)
                    .offset(x: illustrationSize * 0.10, y: -illustrationSize * 0.12)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

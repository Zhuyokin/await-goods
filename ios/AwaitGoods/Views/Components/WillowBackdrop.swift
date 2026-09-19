import SwiftUI

struct WillowBackdrop: View {
    @Environment(\.colorScheme) private var colorScheme
    var illustrationSize: CGFloat = 360

    var body: some View {
        GeometryReader { proxy in
            LinearGradient(
                colors: [HWTheme.listBackground, HWTheme.pageBackground],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay(alignment: .topTrailing) {
                Image("WillowBranches")
                    .resizable()
                    .scaledToFit()
                    .frame(width: illustrationSize, height: illustrationSize)
                    .opacity(colorScheme == .dark ? 0.28 : 0.72)
                    .offset(x: illustrationSize * 0.16, y: -illustrationSize * 0.12)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

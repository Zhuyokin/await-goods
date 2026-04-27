import SwiftUI
import UIKit

enum HWTheme {
    private typealias RGB = (CGFloat, CGFloat, CGFloat)

    private static func adaptive(light: RGB, dark: RGB, alpha: CGFloat = 1) -> Color {
        Color(UIColor { traits in
            let value = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: value.0, green: value.1, blue: value.2, alpha: alpha)
        })
    }

    static let pageBackground = adaptive(light: (0.988, 0.961, 0.910), dark: (0.105, 0.094, 0.078))
    static let listBackground = adaptive(light: (0.996, 0.976, 0.937), dark: (0.130, 0.116, 0.096))
    static let cardBackground = adaptive(light: (1.000, 0.986, 0.956), dark: (0.170, 0.150, 0.122))
    static let fieldBackground = adaptive(light: (0.965, 0.925, 0.858), dark: (0.215, 0.188, 0.150))

    static let primaryText = adaptive(light: (0.160, 0.135, 0.110), dark: (0.940, 0.910, 0.865))
    static let secondaryText = adaptive(light: (0.450, 0.390, 0.325), dark: (0.725, 0.660, 0.575))
    static let tertiaryText = adaptive(light: (0.615, 0.535, 0.445), dark: (0.555, 0.500, 0.435))
    static let separator = adaptive(light: (0.885, 0.815, 0.710), dark: (0.260, 0.228, 0.185))
    static let cardBorder = adaptive(light: (0.910, 0.845, 0.745), dark: (0.335, 0.292, 0.232))

    static let mint = adaptive(light: (0.740, 0.812, 0.650), dark: (0.500, 0.615, 0.410))
    static let freshGreen = adaptive(light: (0.260, 0.635, 0.485), dark: (0.560, 0.760, 0.565))
    static let softWood = adaptive(light: (0.820, 0.660, 0.490), dark: (0.635, 0.500, 0.360))
    static let softBlueGray = adaptive(light: (0.655, 0.715, 0.735), dark: (0.475, 0.550, 0.575))
    static let cream = adaptive(light: (0.988, 0.948, 0.865), dark: (0.155, 0.135, 0.108))
    static let apricot = adaptive(light: (0.945, 0.710, 0.545), dark: (0.725, 0.455, 0.345))
    static let blossom = adaptive(light: (1.000, 0.835, 0.795), dark: (0.675, 0.420, 0.390))
    static let skyWash = adaptive(light: (0.820, 0.940, 0.955), dark: (0.098, 0.140, 0.145))

    static let linkBlue = adaptive(light: (0.475, 0.565, 0.625), dark: (0.555, 0.685, 0.760))
    static let dangerRed = adaptive(light: (0.760, 0.360, 0.300), dark: (0.850, 0.480, 0.420))
    static let softShadow = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.black.withAlphaComponent(0.36)
            : UIColor(red: 0.420, green: 0.285, blue: 0.145, alpha: 0.14)
    })

    static let weChatGreen = freshGreen
    static let sky = softBlueGray
    static let butter = softWood
    static let matcha = mint
    static let lavender = softBlueGray
    static let leafGreen = freshGreen

    static func markColor(_ markColor: MarkColor) -> Color {
        switch markColor {
        case .none: return fieldBackground
        case .green: return adaptive(light: (0.740, 0.812, 0.650), dark: (0.500, 0.615, 0.410))
        case .yellow: return adaptive(light: (0.920, 0.780, 0.535), dark: (0.670, 0.555, 0.355))
        case .pink: return adaptive(light: (0.930, 0.745, 0.680), dark: (0.675, 0.460, 0.430))
        case .gray: return adaptive(light: (0.765, 0.710, 0.650), dark: (0.470, 0.430, 0.380))
        }
    }
}

struct HWSpringBackdrop: View {
    var body: some View {
        HWTheme.pageBackground.ignoresSafeArea()
    }
}

struct HWCreamLeafBackdrop: View {
    private let leaves: [FloatingLeaf] = [
        FloatingLeaf(x: 0.08, size: 15, duration: 13, delay: 0.00, sway: 32, color: HWTheme.mint.opacity(0.20)),
        FloatingLeaf(x: 0.20, size: 8, duration: 10, delay: 0.18, sway: 18, color: HWTheme.blossom.opacity(0.30)),
        FloatingLeaf(x: 0.35, size: 12, duration: 16, delay: 0.38, sway: 24, color: HWTheme.softWood.opacity(0.18)),
        FloatingLeaf(x: 0.49, size: 14, duration: 15, delay: 0.70, sway: 42, color: HWTheme.freshGreen.opacity(0.14)),
        FloatingLeaf(x: 0.66, size: 9, duration: 12, delay: 0.18, sway: 30, color: HWTheme.blossom.opacity(0.28)),
        FloatingLeaf(x: 0.82, size: 18, duration: 17, delay: 0.52, sway: 38, color: HWTheme.mint.opacity(0.17)),
        FloatingLeaf(x: 0.94, size: 11, duration: 14, delay: 0.82, sway: 26, color: HWTheme.softWood.opacity(0.16))
    ]

    var body: some View {
        TimelineView(.animation) { timeline in
            GeometryReader { proxy in
                ZStack {
                    LinearGradient(
                        colors: [HWTheme.skyWash.opacity(0.82), HWTheme.pageBackground, HWTheme.cream],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()

                    CreamBranchCluster()
                        .frame(width: 260, height: 210)
                        .position(x: proxy.size.width - 40, y: 55)
                        .opacity(0.72)

                    CreamBranchCluster()
                        .frame(width: 230, height: 190)
                        .scaleEffect(x: -1, y: 1)
                        .position(x: 45, y: proxy.size.height - 34)
                        .opacity(0.48)

                    CreamBloom(size: 30)
                        .position(x: proxy.size.width - 92, y: 78)
                        .opacity(0.75)

                    CreamBloom(size: 22)
                        .position(x: 48, y: proxy.size.height - 78)
                        .opacity(0.46)

                    ForEach(leaves) { leaf in
                        leaf.view(date: timeline.date, size: proxy.size)
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct CreamBranchCluster: View {
    var body: some View {
        ZStack {
            Capsule()
                .fill(HWTheme.softWood.opacity(0.36))
                .frame(width: 3, height: 230)
                .rotationEffect(.degrees(57))
                .offset(x: 12, y: -6)

            ForEach(0..<10, id: \.self) { index in
                let side: CGFloat = index.isMultiple(of: 2) ? -1 : 1
                let y = CGFloat(index) * 18 - 82
                let x = side * (CGFloat(index % 3) * 9 + 18)

                Capsule()
                    .fill((index.isMultiple(of: 3) ? HWTheme.mint : HWTheme.freshGreen).opacity(0.36))
                    .frame(width: 13 + CGFloat(index % 2) * 3, height: 31 + CGFloat(index % 3) * 4)
                    .rotationEffect(.degrees(Double(side) * (36 + Double(index % 4) * 7)))
                    .offset(x: x, y: y)
            }

            CreamBloom(size: 18)
                .offset(x: -44, y: -76)
            CreamBloom(size: 15)
                .offset(x: 52, y: -40)
            CreamBloom(size: 13)
                .offset(x: 4, y: 50)
        }
    }
}

private struct CreamBloom: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            ForEach(0..<5, id: \.self) { index in
                Capsule()
                    .fill(HWTheme.blossom.opacity(0.72))
                    .frame(width: size * 0.44, height: size * 0.72)
                    .offset(y: -size * 0.26)
                    .rotationEffect(.degrees(Double(index) * 72))
            }

            Circle()
                .fill(HWTheme.cream.opacity(0.86))
                .frame(width: size * 0.24, height: size * 0.24)
        }
    }
}

private struct FloatingLeaf: Identifiable {
    let id = UUID()
    let x: CGFloat
    let size: CGFloat
    let duration: TimeInterval
    let delay: Double
    let sway: CGFloat
    let color: Color

    func view(date: Date, size canvasSize: CGSize) -> some View {
        let rawProgress = (date.timeIntervalSinceReferenceDate / duration + delay).truncatingRemainder(dividingBy: 1)
        let progress = rawProgress < 0 ? rawProgress + 1 : rawProgress
        let visualProgress = CGFloat(progress)
        let y = -40 + (canvasSize.height + 96) * visualProgress
        let wave = CGFloat(sin(progress * .pi * 2))
        let xPosition = canvasSize.width * x + sway * wave
        let rotation = Angle.degrees(progress * 220 + delay * 120)

        return Image(systemName: "leaf.fill")
            .font(.system(size: size, weight: .light))
            .foregroundStyle(color)
            .rotationEffect(rotation)
            .position(x: xPosition, y: y)
            .blur(radius: size > 17 ? 0.15 : 0)
    }
}

extension View {
    func softCard() -> some View {
        self
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(HWTheme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(HWTheme.cardBorder.opacity(0.55))
            )
            .shadow(color: HWTheme.softShadow, radius: 8, x: 0, y: 4)
    }
}
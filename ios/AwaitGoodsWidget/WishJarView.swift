import SwiftUI

struct WishJarCard: Identifiable {
    let id: UUID
    let title: String
    let image: Image?
}

enum WishJarSize {
    case small, medium, large
}

struct WishJarView<Navigation: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let size: WishJarSize
    let cards: [WishJarCard]
    let title: String
    let countText: String
    let savedText: String?
    let targetText: String?
    let progress: Double
    let emptyText: String
    let appIcon: Image
    let selectedID: UUID?
    let navigation: Navigation

    private var focus: WishJarCard? { cards.first { $0.id == selectedID } ?? cards.first }

    private var isSmall: Bool { size == .small }
    private var ink: Color {
        colorScheme == .dark ? Color(red: 0.92, green: 0.95, blue: 0.90) : Color(red: 0.16, green: 0.25, blue: 0.20)
    }
    private var secondary: Color {
        colorScheme == .dark ? Color(red: 0.68, green: 0.76, blue: 0.69) : Color(red: 0.40, green: 0.48, blue: 0.42)
    }

    var body: some View {
        Group {
            if size == .medium {
                HStack(spacing: 8) {
                    WishJarArtwork(cards: cards, selectedID: selectedID)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    VStack(alignment: .leading, spacing: 4) {
                        heading
                        if cards.isEmpty {
                            Text(emptyText)
                                .font(.system(size: 11))
                                .foregroundStyle(secondary)
                                .lineLimit(2)
                        }
                        Spacer(minLength: 0)
                        if let focus {
                            Text(focus.title)
                                .font(.system(size: 13, weight: .medium))
                                .lineLimit(2)
                        }
                        savings
                        if cards.count > 1 { navigation }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 2)
                }
            } else {
                VStack(spacing: isSmall ? 2 : 6) {
                    HStack(alignment: .firstTextBaseline) {
                        heading
                        Spacer(minLength: 4)
                        if !isSmall {
                            Text(countText)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(secondary)
                        }
                    }
                    WishJarArtwork(cards: cards, selectedID: selectedID)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .overlay(alignment: .bottom) {
                            if cards.count > 1 { navigation }
                        }
                    if cards.isEmpty {
                        Text(emptyText)
                            .font(.system(size: isSmall ? 10 : 12))
                            .foregroundStyle(secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    } else if isSmall {
                        HStack(spacing: 4) {
                            Text(countText)
                                .foregroundStyle(secondary)
                            Spacer(minLength: 0)
                            if let savedText {
                                Text(savedText).foregroundStyle(ink)
                            }
                        }
                        .font(.system(size: 10, weight: .medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        if savedText != nil { progressTrack }
                    } else {
                        savings
                    }
                }
            }
        }
        .foregroundStyle(ink)
        .padding(size == .large ? 16 : 12)
    }

    private var heading: some View {
        HStack(spacing: 5) {
            appIcon.resizable()
                .frame(width: isSmall ? 16 : 20, height: isSmall ? 16 : 20)
                .clipShape(RoundedRectangle(cornerRadius: 5))
            Text(title)
                .font(.system(size: isSmall ? 12 : 15, weight: .semibold, design: .serif))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
    }

    @ViewBuilder private var savings: some View {
        if let savedText {
            VStack(alignment: .leading, spacing: size == .medium ? 4 : 7) {
                if size == .large {
                    HStack(alignment: .firstTextBaseline) {
                        Text(savedText).font(.system(size: 19, weight: .medium, design: .rounded))
                        Spacer(minLength: 4)
                        if let targetText {
                            Text(targetText)
                                .font(.system(size: 11))
                                .foregroundStyle(secondary)
                        }
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                } else {
                    Text(savedText)
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                    if let targetText {
                        Text(targetText)
                            .font(.system(size: 10))
                            .foregroundStyle(secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                    }
                }
                progressTrack
            }
        }
    }

    private var progressTrack: some View {
        GeometryReader { geometry in
            Capsule().fill(JarPalette.green.opacity(0.12))
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(LinearGradient(colors: [JarPalette.green.opacity(0.65), JarPalette.green],
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(width: geometry.size.width * min(max(progress, 0), 1))
                }
        }
        .frame(height: isSmall ? 3 : 4)
        .accessibilityLabel(Text(progress, format: .percent.precision(.fractionLength(0))))
    }
}

struct WishJarBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    var body: some View {
        ZStack {
            LinearGradient(colors: colorScheme == .dark
                           ? [Color(red: 0.16, green: 0.21, blue: 0.19), Color(red: 0.08, green: 0.12, blue: 0.11)]
                           : [Color(red: 0.99, green: 0.98, blue: 0.94), Color(red: 0.87, green: 0.93, blue: 0.86)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            GeometryReader { geometry in
                Ellipse()
                    .fill(Color.white.opacity(colorScheme == .dark ? 0.04 : 0.6))
                    .frame(width: geometry.size.width * 0.95, height: geometry.size.height * 0.7)
                    .blur(radius: 25)
                    .offset(x: -geometry.size.width * 0.25, y: -geometry.size.height * 0.15)
                Ellipse()
                    .fill(JarPalette.green.opacity(0.12))
                    .frame(width: geometry.size.width * 0.55, height: geometry.size.height * 0.2)
                    .blur(radius: 18)
                    .offset(x: geometry.size.width * 0.6, y: geometry.size.height * 0.75)
            }
        }
    }
}

private enum JarPalette {
    static let green = Color(red: 0.36, green: 0.54, blue: 0.43)
    static let glass = Color(red: 0.56, green: 0.69, blue: 0.61)
    static let cork = Color(red: 0.66, green: 0.43, blue: 0.23)
}

struct WishJarArtwork: View {
    let cards: [WishJarCard]
    var selectedID: UUID? = nil
    private var focus: WishJarCard? { cards.first { $0.id == selectedID } ?? cards.first }

    var body: some View {
        GeometryReader { geometry in
            let scale = min(geometry.size.width / 240, geometry.size.height / 270)
            ZStack {
                floorShadow
                glassBack
                ZStack {
                    contents
                    if let focus {
                        WishJarFocusedCard(card: focus)
                            .frame(width: cards.count == 1 ? 99 : 92, height: cards.count == 1 ? 117 : 109)
                            .rotationEffect(.degrees(-8))
                            .position(x: 119, y: 184)
                            .id(focus.id)
                            .transition(.asymmetric(insertion: .offset(y: 10).combined(with: .opacity), removal: .opacity))
                    }
                }
                .animation(.easeInOut(duration: 0.6), value: focus?.id)
                .clipShape(JarOutline())
                glassFront
                closure
            }
            .frame(width: 240, height: 270)
            .scaleEffect(scale)
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(cards.map(\.title).joined(separator: ", "))
        .accessibilityValue(focus?.title ?? "")
    }

    private var floorShadow: some View {
        ZStack {
            Ellipse().fill(JarPalette.green.opacity(0.14))
                .frame(width: 188, height: 22).blur(radius: 9)
            Ellipse().fill(Color.black.opacity(0.13))
                .frame(width: 115, height: 8).blur(radius: 4)
        }
        .position(x: 121, y: 255)
    }

    private var glassBack: some View {
        ZStack {
            JarOutline()
                .fill(LinearGradient(stops: [
                    .init(color: .white.opacity(0.55), location: 0),
                    .init(color: JarPalette.glass.opacity(0.14), location: 0.14),
                    .init(color: .white.opacity(0.05), location: 0.4),
                    .init(color: .white.opacity(0.22), location: 0.7),
                    .init(color: JarPalette.glass.opacity(0.28), location: 1)
                ], startPoint: .topLeading, endPoint: .bottomTrailing))
            Ellipse()
                .fill(LinearGradient(colors: [.white.opacity(0.3), JarPalette.glass.opacity(0.32)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: 153, height: 23)
                .overlay(Ellipse().stroke(.white.opacity(0.8), lineWidth: 1.5))
                .position(x: 120, y: 237)
        }
    }

    private var contents: some View {
        let focusedID = focus?.id
        return Canvas { context, _ in
            if cards.isEmpty {
                context.draw(Text(Image(systemName: "heart"))
                    .font(.system(size: 36, weight: .ultraLight))
                    .foregroundColor(JarPalette.green.opacity(0.5)), at: CGPoint(x: 120, y: 176))
            }
            // A single drawing surface keeps the view tree small for large collections.
            for (index, card) in cards.enumerated() {
                guard card.id != focusedID else { continue }
                let pose = WishJarLayout.pose(index: index, count: cards.count)
                var cardContext = context
                cardContext.translateBy(x: pose.x, y: pose.y)
                cardContext.rotate(by: .degrees(pose.angle))
                let width = pose.width
                let height = width * 1.18
                let rect = CGRect(x: -width / 2, y: -height / 2, width: width, height: height)
                let paper = Path(roundedRect: rect, cornerRadius: width * 0.035)
                var shadow = cardContext
                shadow.addFilter(.shadow(color: .black.opacity(0.22), radius: width * 0.035, x: 1, y: width * 0.04))
                shadow.fill(paper, with: .color(Color(red: 1, green: 0.99, blue: 0.95)))
                cardContext.stroke(paper, with: .color(.white.opacity(0.9)), lineWidth: 0.7)
                let photoRect = CGRect(x: -width * 0.44, y: -height / 2 + width * 0.06,
                                       width: width * 0.88, height: width * 0.88)
                cardContext.fill(Path(roundedRect: photoRect, cornerRadius: 1.5),
                                 with: .color(Color(red: 0.94, green: 0.95, blue: 0.91)))
                if let image = card.image {
                    let resolved = cardContext.resolve(image)
                    let factor = min(photoRect.width / max(resolved.size.width, 1),
                                     photoRect.height / max(resolved.size.height, 1))
                    let imageSize = CGSize(width: resolved.size.width * factor, height: resolved.size.height * factor)
                    cardContext.draw(resolved, in: CGRect(x: photoRect.midX - imageSize.width / 2,
                                                         y: photoRect.midY - imageSize.height / 2,
                                                         width: imageSize.width, height: imageSize.height))
                } else {
                    cardContext.draw(Text(Image(systemName: "gift"))
                        .font(.system(size: width * 0.3, weight: .light))
                        .foregroundColor(JarPalette.green), at: CGPoint(x: 0, y: photoRect.midY))
                }
                var captionContext = cardContext
                let captionRect = CGRect(x: -width * 0.43, y: height / 2 - width * 0.19,
                                         width: width * 0.86, height: width * 0.13)
                captionContext.clip(to: Path(captionRect))
                captionContext.draw(Text(card.title).font(.system(size: width * 0.085, weight: .medium, design: .serif))
                    .foregroundColor(Color(red: 0.28, green: 0.34, blue: 0.29)),
                                    at: CGPoint(x: 0, y: captionRect.midY))
            }
        }
        .frame(width: 240, height: 270)
    }

    private var glassFront: some View {
        ZStack {
            JarOutline()
                .stroke(LinearGradient(colors: [JarPalette.glass.opacity(0.65), .white.opacity(0.9),
                                                JarPalette.glass.opacity(0.6), .white.opacity(0.85)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 4)
            JarOutline()
                .stroke(.white.opacity(0.65), lineWidth: 1)
            Canvas { context, _ in
                var left = Path()
                left.move(to: CGPoint(x: 69, y: 90))
                left.addCurve(to: CGPoint(x: 47, y: 205), control1: CGPoint(x: 40, y: 103), control2: CGPoint(x: 44, y: 162))
                context.stroke(left, with: .color(.white.opacity(0.75)), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                var right = Path()
                right.move(to: CGPoint(x: 176, y: 100))
                right.addCurve(to: CGPoint(x: 191, y: 218), control1: CGPoint(x: 200, y: 122), control2: CGPoint(x: 193, y: 187))
                context.stroke(right, with: .color(.white.opacity(0.6)), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                var base = Path()
                base.move(to: CGPoint(x: 60, y: 235))
                base.addCurve(to: CGPoint(x: 179, y: 236), control1: CGPoint(x: 82, y: 250), control2: CGPoint(x: 158, y: 250))
                context.stroke(base, with: .color(.white.opacity(0.85)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
            }
            Capsule().fill(.white.opacity(0.4))
                .frame(width: 10, height: 71)
                .blur(radius: 1.5)
                .rotationEffect(.degrees(3))
                .position(x: 56, y: 144)
            Capsule().fill(.white.opacity(0.25))
                .frame(width: 4, height: 37)
                .position(x: 181, y: 170)
            Ellipse().fill(.white.opacity(0.2))
                .frame(width: 52, height: 12)
                .rotationEffect(.degrees(-24))
                .position(x: 76, y: 93)
        }
        .allowsHitTesting(false)
    }

    private var closure: some View {
        ZStack {
            // The neck sits above the contents so the cards stay behind the glass lip.
            RoundedRectangle(cornerRadius: 7)
                .fill(LinearGradient(colors: [.white.opacity(0.6), JarPalette.glass.opacity(0.35), .white.opacity(0.7)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: 99, height: 16)
                .overlay(RoundedRectangle(cornerRadius: 7).stroke(.white.opacity(0.8), lineWidth: 1.5))
                .position(x: 120, y: 53)
            cork
                .position(x: 120, y: 35)
            Canvas { context, _ in
                var twine = Path()
                twine.move(to: CGPoint(x: 75, y: 63))
                twine.addCurve(to: CGPoint(x: 165, y: 62), control1: CGPoint(x: 98, y: 70), control2: CGPoint(x: 145, y: 69))
                twine.addCurve(to: CGPoint(x: 171, y: 93), control1: CGPoint(x: 158, y: 77), control2: CGPoint(x: 171, y: 79))
                context.stroke(twine, with: .color(JarPalette.cork), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                var bow = Path()
                bow.move(to: CGPoint(x: 158, y: 65))
                bow.addCurve(to: CGPoint(x: 147, y: 56), control1: CGPoint(x: 127, y: 46), control2: CGPoint(x: 134, y: 46))
                bow.addQuadCurve(to: CGPoint(x: 158, y: 65), control: CGPoint(x: 151, y: 61))
                bow.addCurve(to: CGPoint(x: 170, y: 54), control1: CGPoint(x: 178, y: 34), control2: CGPoint(x: 192, y: 54))
                bow.addLine(to: CGPoint(x: 158, y: 65))
                context.stroke(bow, with: .color(JarPalette.cork.opacity(0.85)), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
            }
            JarTag()
                .frame(width: 30, height: 42)
                .rotationEffect(.degrees(-21), anchor: .top)
                .position(x: 173, y: 100)
        }
    }

    private var cork: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 5)
                .fill(LinearGradient(colors: [Color(red: 0.84, green: 0.66, blue: 0.43), JarPalette.cork,
                                              Color(red: 0.48, green: 0.30, blue: 0.16)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay {
                    Canvas { context, size in
                        for index in 0..<48 {
                            let x = CGFloat((index * 29 + 7) % 88)
                            let y = CGFloat((index * 13 + 5) % 20) + 4
                            context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: index % 3 == 0 ? 3 : 1.2, height: 1)),
                                         with: .color(Color(red: 0.31, green: 0.20, blue: 0.11).opacity(0.3)))
                        }
                    }
                }
            Ellipse()
                .fill(LinearGradient(colors: [Color(red: 0.92, green: 0.79, blue: 0.58), Color(red: 0.74, green: 0.55, blue: 0.33)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(height: 11)
                .overlay(Ellipse().stroke(Color.white.opacity(0.45), lineWidth: 1))
                .offset(y: -3)
        }
        .frame(width: 88, height: 27)
        .shadow(color: .black.opacity(0.12), radius: 2, y: 3)
    }
}

private struct JarOutline: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 77, y: 53))
        path.addLine(to: CGPoint(x: 77, y: 71))
        path.addCurve(to: CGPoint(x: 37, y: 117), control1: CGPoint(x: 76, y: 88), control2: CGPoint(x: 37, y: 83))
        path.addCurve(to: CGPoint(x: 40, y: 225), control1: CGPoint(x: 34, y: 148), control2: CGPoint(x: 35, y: 207))
        path.addCurve(to: CGPoint(x: 72, y: 246), control1: CGPoint(x: 43, y: 240), control2: CGPoint(x: 55, y: 246))
        path.addCurve(to: CGPoint(x: 169, y: 246), control1: CGPoint(x: 99, y: 253), control2: CGPoint(x: 146, y: 252))
        path.addCurve(to: CGPoint(x: 200, y: 225), control1: CGPoint(x: 188, y: 244), control2: CGPoint(x: 197, y: 239))
        path.addCurve(to: CGPoint(x: 203, y: 117), control1: CGPoint(x: 205, y: 198), control2: CGPoint(x: 205, y: 145))
        path.addCurve(to: CGPoint(x: 163, y: 71), control1: CGPoint(x: 202, y: 85), control2: CGPoint(x: 164, y: 89))
        path.addLine(to: CGPoint(x: 163, y: 53))
        path.closeSubpath()
        return path.applying(CGAffineTransform(scaleX: rect.width / 240, y: rect.height / 270))
    }
}

private struct JarTag: View {
    var body: some View {
        VStack(spacing: 5) {
            Circle().fill(JarPalette.cork.opacity(0.6)).frame(width: 3, height: 3)
            Image(systemName: "heart")
                .font(.system(size: 12, weight: .light))
                .foregroundStyle(JarPalette.cork)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.98, green: 0.92, blue: 0.77), in: RoundedRectangle(cornerRadius: 3))
        .overlay(RoundedRectangle(cornerRadius: 3).inset(by: 3).stroke(JarPalette.cork.opacity(0.3), lineWidth: 0.6))
        .shadow(color: .black.opacity(0.1), radius: 2, x: 1, y: 2)
    }
}

struct WishJarControlLabel: View {
    let symbol: String
    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(JarPalette.green)
            .frame(width: 32, height: 32)
            .background(JarPalette.green.opacity(0.10), in: Circle())
    }
}

private struct WishJarFocusedCard: View {
    let card: WishJarCard
    var body: some View {
        VStack(spacing: 3) {
            ZStack {
                Color(red: 0.94, green: 0.95, blue: 0.91)
                if let image = card.image {
                    image.resizable().scaledToFit().padding(2)
                } else {
                    Image(systemName: "gift")
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(JarPalette.green)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 2))
            Text(card.title)
                .font(.system(size: 8, weight: .medium, design: .serif))
                .foregroundStyle(Color(red: 0.28, green: 0.34, blue: 0.29))
                .lineLimit(1)
                .frame(height: 11)
        }
        .padding(5)
        .padding(.bottom, 2)
        .background(Color(red: 1, green: 0.99, blue: 0.95), in: RoundedRectangle(cornerRadius: 3))
        .overlay(RoundedRectangle(cornerRadius: 3).stroke(.white.opacity(0.9), lineWidth: 0.7))
        .shadow(color: .black.opacity(0.22), radius: 3, x: 1, y: 3)
    }
}

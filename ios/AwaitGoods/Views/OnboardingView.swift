import SwiftUI

struct OnboardingView: View {
    @AppStorage("appLanguage") private var appLanguageRawValue = AppLanguage.zhHans.rawValue
    @State private var languageCarouselIndex = 0
    @State private var showcasedLanguageRawValue = AppLanguage.zhHans.rawValue
    @State private var languageSelectorWasTouched = false

    let onComplete: () -> Void
    private let languageCarouselTimer = Timer.publish(every: 1.7, on: .main, in: .common).autoconnect()

    private var appLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguageRawValue) ?? .zhHans
    }

    var body: some View {
        ZStack {
            HWTheme.pageBackground.ignoresSafeArea()
            OnboardingPaperBackdrop()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        hero
                        languageSelector
                        featureList
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 28)
                    .padding(.bottom, 20)
                }

                Button(action: onComplete) {
                    Text(appLanguage.text("开始使用"))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(HWTheme.cardBackground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(HWTheme.freshGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 22)
                .padding(.top, 12)
                .padding(.bottom, 18)
                .background(HWTheme.pageBackground.opacity(0.92))
            }
        }
        .environment(\.appLanguage, appLanguage)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 18) {
            OnboardingPoeticMark()
                .frame(height: 248)

            VStack(alignment: .leading, spacing: 8) {
                Text(appLanguage.text("给心愿一点等待的形状"))
                    .font(.system(size: 31, weight: .semibold, design: .serif))
                    .foregroundStyle(HWTheme.primaryText)
                    .fixedSize(horizontal: false, vertical: true)

                Text(appLanguage.text("不是购物车，是一页留白。把想买、想存和想放下的东西，慢慢整理到同一张纸上。"))
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(HWTheme.secondaryText)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var languageSelector: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 7) {
                Text(appLanguage.text("语言"))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(HWTheme.secondaryText)

                Spacer(minLength: 8)

                Label(appLanguage.text("轻触切换语言"), systemImage: "hand.tap")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(HWTheme.tertiaryText)
                    .labelStyle(.titleAndIcon)
            }

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(AppLanguage.allCases) { language in
                            let isSelected = appLanguageRawValue == language.rawValue
                            let isShowcased = showcasedLanguageRawValue == language.rawValue && !isSelected

                            Button {
                                languageSelectorWasTouched = true
                                appLanguageRawValue = language.rawValue
                                showcasedLanguageRawValue = language.rawValue
                                languageCarouselIndex = AppLanguage.allCases.firstIndex(of: language) ?? languageCarouselIndex
                                withAnimation(.easeInOut(duration: 0.35)) {
                                    proxy.scrollTo(language.rawValue, anchor: .center)
                                }
                            } label: {
                                Text(language.title)
                                    .font(.system(size: 14, weight: isSelected ? .medium : .regular))
                                    .foregroundStyle(isSelected ? HWTheme.cardBackground : isShowcased ? HWTheme.freshGreen : HWTheme.secondaryText)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(isSelected ? HWTheme.freshGreen.opacity(0.86) : isShowcased ? HWTheme.mint.opacity(0.24) : HWTheme.cardBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(isSelected ? Color.clear : isShowcased ? HWTheme.freshGreen.opacity(0.58) : HWTheme.cardBorder.opacity(0.58), lineWidth: 0.8)
                                    )
                                    .scaleEffect(isShowcased ? 1.04 : 1)
                                    .animation(.easeInOut(duration: 0.24), value: showcasedLanguageRawValue)
                            }
                            .id(language.rawValue)
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .onAppear {
                    showcasedLanguageRawValue = appLanguageRawValue
                    languageCarouselIndex = AppLanguage.allCases.firstIndex { $0.rawValue == appLanguageRawValue } ?? 0
                }
                .onReceive(languageCarouselTimer) { _ in
                    guard !languageSelectorWasTouched else { return }
                    let languages = AppLanguage.allCases
                    guard !languages.isEmpty else { return }

                    languageCarouselIndex = (languageCarouselIndex + 1) % languages.count
                    let rawValue = languages[languageCarouselIndex].rawValue
                    withAnimation(.easeInOut(duration: 0.42)) {
                        showcasedLanguageRawValue = rawValue
                        proxy.scrollTo(rawValue, anchor: .center)
                    }
                }
            }
        }
    }

    private var featureList: some View {
        VStack(spacing: 10) {
            OnboardingFeatureRow(
                number: "01",
                title: appLanguage.text("先记下每个心愿"),
                message: appLanguage.text("填写名称、价格、已存金额、分类和链接，让想买变得清楚。")
            )

            OnboardingFeatureRow(
                number: "02",
                title: appLanguage.text("用进度决定节奏"),
                message: appLanguage.text("在详情页继续存入或一键补满，慢慢靠近真正值得拥有的东西。")
            )

            OnboardingFeatureRow(
                number: "03",
                title: appLanguage.text("轻松整理和备份"),
                message: appLanguage.text("搜索、筛选、拖动排序、桌面小组件和 JSON 导出都可以随时使用。")
            )
        }
    }
}

private struct OnboardingPoeticMark: View {
    @Environment(\.appLanguage) private var appLanguage

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(HWTheme.cardBackground.opacity(0.72))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(HWTheme.cardBorder.opacity(0.58), lineWidth: 0.8)
                    )

                VStack(spacing: 15) {
                    ForEach(0..<6, id: \.self) { index in
                        Rectangle()
                            .fill(index == 0 ? HWTheme.freshGreen.opacity(0.18) : HWTheme.separator.opacity(0.18))
                            .frame(height: index == 0 ? 1.2 : 0.8)
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 28)

                Text("候")
                    .font(.system(size: 112, weight: .light, design: .serif))
                    .foregroundStyle(HWTheme.freshGreen.opacity(0.18))
                    .position(x: width * 0.24, y: height * 0.40)

                Text("物")
                    .font(.system(size: 88, weight: .ultraLight, design: .serif))
                    .foregroundStyle(HWTheme.softWood.opacity(0.18))
                    .position(x: width * 0.72, y: height * 0.63)

                VStack(alignment: .leading, spacing: 9) {
                    Text(appLanguage.text("今日先不急着拥有"))
                        .font(.system(size: 16, weight: .medium, design: .serif))
                        .foregroundStyle(HWTheme.primaryText)

                    OnboardingReceiptLine(label: appLanguage.text("想买"), value: "3")
                    OnboardingReceiptLine(label: appLanguage.text("已存"), value: "62%")
                    OnboardingReceiptLine(label: appLanguage.text("放下"), value: "1")
                }
                .padding(15)
                .frame(width: min(width * 0.58, 220), alignment: .leading)
                .background(HWTheme.listBackground.opacity(0.88))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(HWTheme.cardBorder.opacity(0.55), lineWidth: 0.8)
                )
                .rotationEffect(.degrees(-2))
                .position(x: width * 0.41, y: height * 0.62)

                VStack(alignment: .leading, spacing: 5) {
                    Text("Await")
                    Text("Goods")
                }
                .font(.system(size: 19, weight: .semibold, design: .serif))
                .foregroundStyle(HWTheme.primaryText.opacity(0.88))
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(HWTheme.fieldBackground.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .rotationEffect(.degrees(4))
                .position(x: width * 0.76, y: height * 0.28)
            }
        }
    }
}

private struct OnboardingReceiptLine: View {
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(HWTheme.secondaryText)

            Rectangle()
                .fill(HWTheme.separator.opacity(0.45))
                .frame(height: 0.8)

            Text(value)
                .font(.system(size: 12, weight: .medium).monospacedDigit())
                .foregroundStyle(HWTheme.freshGreen)
        }
    }
}

private struct OnboardingFeatureRow: View {
    let number: String
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(size: 14, weight: .semibold, design: .serif).monospacedDigit())
                .foregroundStyle(HWTheme.freshGreen)
                .frame(width: 38, height: 38)
                .background(HWTheme.mint.opacity(0.22))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(HWTheme.primaryText)

                Text(message)
                    .font(.system(size: 13))
                    .foregroundStyle(HWTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(HWTheme.cardBackground.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(HWTheme.cardBorder.opacity(0.58), lineWidth: 0.8)
        )
    }
}

private struct OnboardingPaperBackdrop: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Rectangle()
                    .fill(HWTheme.listBackground.opacity(0.42))
                    .frame(width: proxy.size.width * 0.72, height: 68)
                    .rotationEffect(.degrees(-7))
                    .position(x: proxy.size.width * 0.18, y: 78)

                Rectangle()
                    .fill(HWTheme.separator.opacity(0.16))
                    .frame(width: 1, height: proxy.size.height * 0.68)
                    .position(x: proxy.size.width - 34, y: proxy.size.height * 0.5)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

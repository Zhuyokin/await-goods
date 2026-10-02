import Photos
import SwiftUI
import UIKit

struct SharePostersView: View {
    @Environment(\.appLanguage) private var appLanguage
    @State private var selectedPosterIndex = 0
    @State private var isSaving = false
    @State private var alertMessage: String?
    @State private var sharedPoster: SharedPoster?

    private let posterTitles = [
        "功能概览", "心愿清单", "存钱进度", "理性消费", "心愿统计",
        "主题", "添加心愿", "桌面小组件", "心愿罐",
    ]

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 16) {
                    TabView(selection: $selectedPosterIndex) {
                        ForEach(posterTitles.indices, id: \.self) { index in
                            Image("SharePoster\(index)")
                                .resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: HWTheme.softShadow, radius: 8, y: 4)
                                .padding(.horizontal, 8)
                                .padding(.bottom, 36)
                                .tag(index)
                                .accessibilityLabel(appLanguage.text(posterTitles[index]))
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .always))
                    .indexViewStyle(.page(backgroundDisplayMode: .always))
                    .frame(height: max(300, geometry.size.height - 180))
                    .accessibilityIdentifier("share-app.posters")

                    Text(appLanguage.text("左右滑动，选择要保存或分享的海报"))
                        .font(.footnote)
                        .foregroundStyle(HWTheme.secondaryText)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 12) {
                        Button(action: savePoster) {
                            HStack(spacing: 8) {
                                if isSaving {
                                    ProgressView()
                                } else {
                                    Image(systemName: "square.and.arrow.down")
                                }
                                Text(appLanguage.text("保存海报"))
                            }
                            .frame(maxWidth: .infinity, minHeight: 32)
                        }
                        .buttonStyle(.bordered)
                        .disabled(isSaving)
                        .accessibilityIdentifier("share-app.save")

                        Button(action: sharePoster) {
                            Label(appLanguage.text("分享海报"), systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity, minHeight: 32)
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityIdentifier("share-app.share-poster")
                    }
                    .font(.subheadline.weight(.semibold))
                }
                .padding(16)
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
            }
        }
        .background { IllustrationBackdrop() }
        .tint(HWTheme.freshGreen)
        .navigationTitle(appLanguage.text("分享 App"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: AppStoreLinks.appURL) {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel(appLanguage.text("分享 App Store 链接"))
                .accessibilityIdentifier("share-app.link")
            }
        }
        .sheet(item: $sharedPoster) { poster in
            PosterActivitySheet(image: poster.image)
        }
        .alert(appLanguage.text("分享 App"), isPresented: Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )) {
            Button(appLanguage.text("完成"), role: .cancel) { alertMessage = nil }
        } message: {
            if let alertMessage {
                Text(appLanguage.text(alertMessage))
            }
        }
    }

    private func sharePoster() {
        guard let image = UIImage(named: "SharePoster\(selectedPosterIndex)") else {
            alertMessage = "无法加载海报，请重试"
            return
        }
        sharedPoster = SharedPoster(image: image)
    }

    private func savePoster() {
        guard let image = UIImage(named: "SharePoster\(selectedPosterIndex)") else {
            alertMessage = "无法加载海报，请重试"
            return
        }
        isSaving = true
        Task { @MainActor in
            defer { isSaving = false }
            let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            guard status == .authorized || status == .limited else {
                alertMessage = "请在系统设置中允许添加照片，以保存海报。"
                return
            }
            do {
                try await PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                }
                alertMessage = "海报已保存到相册"
            } catch {
                alertMessage = "无法保存海报，请重试"
            }
        }
    }
}

private struct SharedPoster: Identifiable {
    let id = UUID()
    let image: UIImage
}

private struct PosterActivitySheet: UIViewControllerRepresentable {
    let image: UIImage

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [image], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

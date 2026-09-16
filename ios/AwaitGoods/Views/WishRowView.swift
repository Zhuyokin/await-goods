import ImageIO
import PhotosUI
import SwiftUI
import UIKit

struct WishRowView: View {
    @Environment(\.appLanguage) private var appLanguage
    @ScaledMetric(relativeTo: .body) private var photoWidth = 88.0

    let item: WishItem
    let isEditing: Bool
    let isSelected: Bool
    let onCheck: () -> Void
    let onOpen: () -> Void
    let onMore: (() -> Void)?

    var body: some View {
        HStack(spacing: 10) {
            if isEditing {
                Button(action: onCheck) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                        .foregroundStyle(isSelected ? HWTheme.freshGreen : HWTheme.tertiaryText)
                        .frame(width: 32, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(appLanguage.text("整理清单"))
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }

            Button(action: onOpen) {
                HStack(alignment: .top, spacing: 12) {
                    WishPhoto(
                        data: item.photoData,
                        width: min(photoWidth, 112),
                        height: 112,
                        fallbackIcon: thumbnailIcon,
                        fallbackColor: thumbnailColor
                    )
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 5) {
                        HStack(alignment: .top, spacing: 6) {
                            Text(item.title)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(HWTheme.primaryText)
                                .strikethrough(item.status == .released, color: HWTheme.secondaryText)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            priorityBadge
                        }

                        Text(appLanguage.text(item.category.isEmpty ? "未分类" : item.category))
                            .font(.system(size: 12))
                            .foregroundStyle(HWTheme.secondaryText)
                            .lineLimit(1)

                        HStack(spacing: 8) {
                            Text(item.price.map(moneyText) ?? appLanguage.text("目标未定"))
                                .font(.system(size: 19, weight: .semibold).monospacedDigit())
                                .foregroundStyle(HWTheme.primaryText)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundStyle(HWTheme.tertiaryText)
                                .accessibilityHidden(true)
                        }

                        if let target = item.savingsTarget {
                            Text("\(appLanguage.text("已存")) \(moneyText(item.savedAmountValue)) / \(moneyText(target))")
                                .font(.system(size: 11).monospacedDigit())
                                .foregroundStyle(HWTheme.secondaryText)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                            HStack(spacing: 8) {
                                WishProgressBar(progress: item.savingsProgress)
                                Text("\(Int((item.savingsProgress * 100).rounded()))%")
                                    .font(.system(size: 11).monospacedDigit())
                                    .foregroundStyle(HWTheme.secondaryText)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(HWTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: HWTheme.softShadow.opacity(0.5), radius: 8, x: 0, y: 3)
        .contextMenu {
            if let onMore, !isEditing {
                Button(appLanguage.text("编辑"), systemImage: "pencil", action: onMore)
            }
        }
    }

    private var thumbnailIcon: String {
        let value = item.category.lowercased()
        if value.contains("数码") || value.contains("digital") { return "laptopcomputer" }
        if value.contains("衣") || value.contains("cloth") { return "tshirt" }
        if value.contains("家居") || value.contains("home") { return "house" }
        if value.contains("书") || value.contains("book") { return "books.vertical" }
        if value.contains("礼物") || value.contains("gift") { return "gift" }
        if value.contains("运动") || value.contains("sport") { return "figure.run" }
        if value.contains("体验") || value.contains("travel") { return "airplane" }
        return "bag"
    }

    private var thumbnailColor: Color {
        if item.markColor != .none { return HWTheme.markColor(item.markColor) }
        switch item.status {
        case .waiting: return HWTheme.freshGreen
        case .bought: return HWTheme.softBlueGray
        case .released: return HWTheme.tertiaryText
        }
    }

    private var priorityBadge: some View {
        HStack(spacing: 4) {
            Circle().fill(priorityColor).frame(width: 4, height: 4)
            Text(appLanguage.text(item.priority.title))
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundStyle(priorityColor)
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(priorityColor.opacity(0.10), in: Capsule())
        .fixedSize()
        .accessibilityLabel("\(appLanguage.text("优先级")) \(appLanguage.text(item.priority.title))")
    }

    private var priorityColor: Color {
        switch item.priority {
        case .low: return HWTheme.freshGreen
        case .medium: return HWTheme.apricot
        case .high: return HWTheme.dangerRed
        }
    }

    private func moneyText(_ value: Double) -> String {
        "$\(value.formatted(.number.precision(.fractionLength(0...2))))"
    }
}

struct WishProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geometry in
            Capsule()
                .fill(HWTheme.separator.opacity(0.3))
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(HWTheme.freshGreen.opacity(0.8))
                        .frame(width: geometry.size.width * min(max(progress, 0), 1))
                }
        }
        .frame(height: 4)
        .accessibilityLabel(Text("\(Int((progress * 100).rounded()))%"))
    }
}

struct WishPhoto: View {
    let data: Data?
    var width: CGFloat = 82
    var height: CGFloat = 82
    var fallbackIcon = "photo"
    var fallbackColor: Color = HWTheme.tertiaryText

    var body: some View {
        Group {
            if let data, let photo = UIImage(data: data) {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: fallbackIcon)
                    .font(.system(size: 27, weight: .regular))
                    .foregroundStyle(fallbackColor)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(fallbackColor.opacity(0.11))
            }
        }
        .frame(width: width, height: height)
        .background(photoBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var photoBackground: Color {
        #if DEBUG
        if ScreenshotSeedService.isEnabled, data != nil { return .clear }
        #endif
        return HWTheme.fieldBackground
    }
}

struct WishPhotoPicker: View {
    @Environment(\.appLanguage) private var appLanguage
    @Binding var photoData: Data?
    @Binding var isLoading: Bool
    @State private var selection: PhotosPickerItem?
    @State private var loadingRequest = UUID()
    @State private var showingError = false

    var body: some View {
        HStack(spacing: 12) {
            PhotosPicker(selection: $selection, matching: .images) {
                HStack(spacing: 12) {
                    WishPhoto(data: photoData, width: 64, height: 64)
                    Text(appLanguage.text(photoData == nil ? "添加商品图片" : "更换商品图片"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(HWTheme.freshGreen)
                }
            }
            .buttonStyle(.plain)
            Spacer(minLength: 0)
            if isLoading {
                ProgressView()
            } else if photoData != nil {
                Button(appLanguage.text("删除"), role: .destructive) {
                    selection = nil
                    photoData = nil
                }
                .font(.system(size: 12))
            }
        }
        .task(id: selection) {
            guard let selection else { return }
            let request = UUID()
            loadingRequest = request
            isLoading = true
            defer {
                if loadingRequest == request { isLoading = false }
            }
            do {
                guard let data = try await selection.loadTransferable(type: Data.self),
                      let source = CGImageSourceCreateWithData(data as CFData, nil),
                      let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                        kCGImageSourceCreateThumbnailFromImageAlways: true,
                        kCGImageSourceCreateThumbnailWithTransform: true,
                        kCGImageSourceThumbnailMaxPixelSize: 800
                      ] as CFDictionary),
                      let jpeg = UIImage(cgImage: thumbnail).jpegData(compressionQuality: 0.85) else {
                    if !Task.isCancelled { showingError = true }
                    return
                }
                guard !Task.isCancelled else { return }
                photoData = jpeg
            } catch {
                if !Task.isCancelled { showingError = true }
            }
        }
        .alert(appLanguage.text("无法读取图片，请重试"), isPresented: $showingError) {
            Button(appLanguage.text("完成"), role: .cancel) { selection = nil }
        }
    }
}

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
        WishCurrency.format(value, code: item.currencyCode)
    }
}

struct WishGridCard: View {
    @Environment(\.appLanguage) private var appLanguage
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var titleSize = 15.0
    @ScaledMetric(relativeTo: .title3) private var amountSize = 20.0

    let item: WishItem
    let width: CGFloat
    let isEditing: Bool
    let isSelected: Bool
    let onOpen: () -> Void
    let onPin: () -> Void
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onCopyLink: () -> Void
    let onColor: (MarkColor) -> Void
    let onStatus: (WishItemStatus) -> Void
    let onDelete: () -> Void

    private var photoWidth: CGFloat { max(width - 24, 1) }
    private var photoHeight: CGFloat { min(photoWidth * 0.79, 180) }

    var body: some View {
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: 8) {
                WishPhoto(data: item.photoData, width: max(photoWidth - 20, 1), height: max(photoHeight - 16, 1),
                          fallbackIcon: "bag", fallbackColor: HWTheme.freshGreen)
                    .frame(width: photoWidth, height: photoHeight)
                    .background(HWTheme.fieldBackground.opacity(0.7), in: RoundedRectangle(cornerRadius: 14))
                    .overlay(alignment: .topLeading) { pinBadge }
                    .overlay(alignment: .topTrailing) { selectionBadge }
                    .overlay(alignment: .bottomLeading) {
                        if item.markColor != .none {
                            Circle().fill(HWTheme.markColor(item.markColor)).frame(width: 10, height: 10)
                                .overlay(Circle().stroke(HWTheme.cardBackground, lineWidth: 2)).padding(8)
                        }
                    }
                    .accessibilityHidden(true)
                Text(item.title)
                    .font(.system(size: titleSize, weight: .semibold))
                    .foregroundStyle(HWTheme.primaryText)
                    .strikethrough(item.status == .released, color: HWTheme.secondaryText)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(item.price.map(moneyText) ?? appLanguage.text("目标未定"))
                        .font(.system(size: amountSize, weight: .semibold, design: .rounded).monospacedDigit())
                        .foregroundStyle(HWTheme.primaryText)
                        .lineLimit(1).minimumScaleFactor(0.65)
                    Spacer(minLength: 0)
                    if item.savingsTarget != nil {
                        Text("\(Int((item.savingsProgress * 100).rounded()))%")
                            .font(.caption2.monospacedDigit()).foregroundStyle(HWTheme.freshGreen)
                    }
                }
                WishProgressBar(progress: item.savingsProgress)
                    .opacity(item.savingsTarget == nil ? 0 : 1)
                Text("\(appLanguage.text("已存")) \(moneyText(item.savedAmountValue))")
                    .font(.caption).foregroundStyle(HWTheme.secondaryText)
                    .lineLimit(1).minimumScaleFactor(0.8)
            }
            .padding(12)
            .frame(width: width, alignment: .topLeading)
            .background(HWTheme.cardBackground, in: RoundedRectangle(cornerRadius: 21))
            .overlay(RoundedRectangle(cornerRadius: 21)
                .stroke(isSelected && isEditing ? HWTheme.freshGreen.opacity(0.72) : HWTheme.cardBorder.opacity(0.22),
                        lineWidth: isSelected && isEditing ? 1.5 : 0.6))
            .contentShape(RoundedRectangle(cornerRadius: 21))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected && isEditing ? .isSelected : [])
        .accessibilityValue(appLanguage.text(item.status.title) + (item.isPinned ? ", " + appLanguage.text("已置顶") : ""))
        .contextMenu {
            if !isEditing {
                Button(appLanguage.text(item.isPinned ? "取消置顶" : "置顶"), systemImage: item.isPinned ? "pin.slash" : "pin", action: onPin)
                Button(appLanguage.text("编辑"), systemImage: "pencil", action: onEdit)
                Button(appLanguage.text("选择"), systemImage: "checkmark.circle", action: onSelect)
                Divider()
                Menu(appLanguage.text("状态"), systemImage: "heart") {
                    ForEach(WishItemStatus.allCases) { status in
                        Button(appLanguage.text(status.title), systemImage: status.iconName) { onStatus(status) }
                            .disabled(item.status == status)
                    }
                }
                Menu(appLanguage.text("标记"), systemImage: "tag") {
                    ForEach(MarkColor.allCases) { color in
                        Button { onColor(color) } label: {
                            Text(appLanguage.text(color.title))
                            if item.markColor == color { Image(systemName: "checkmark") }
                        }
                    }
                }
                if item.linkURL != nil {
                    Button(appLanguage.text("复制链接"), systemImage: "link", action: onCopyLink)
                }
                Divider()
                Button(appLanguage.text("移入回收站"), systemImage: "trash", role: .destructive, action: onDelete)
            }
        }
    }

    @ViewBuilder private var pinBadge: some View {
        if item.isPinned {
            Image(systemName: "pin.fill").font(.system(size: 11)).rotationEffect(.degrees(30))
                .foregroundStyle(HWTheme.freshGreen).frame(width: 26, height: 26)
                .background(HWTheme.cardBackground.opacity(0.95), in: Circle()).padding(7)
        }
    }

    @ViewBuilder private var selectionBadge: some View {
        if isEditing {
            Circle().fill(isSelected ? HWTheme.freshGreen : HWTheme.cardBackground)
                .overlay(Circle().stroke(isSelected ? HWTheme.freshGreen : HWTheme.tertiaryText.opacity(0.5), lineWidth: 1.3))
                .overlay {
                    if isSelected {
                        Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundStyle(.white)
                    }
                }
                .frame(width: 24, height: 24).padding(7)
        } else if item.status != .waiting {
            Image(systemName: item.status.iconName).font(.system(size: 11, weight: .semibold))
                .foregroundStyle(HWTheme.secondaryText).frame(width: 26, height: 26)
                .background(HWTheme.cardBackground.opacity(0.95), in: Circle()).padding(7)
        }
    }

    private func moneyText(_ value: Double) -> String {
        WishCurrency.format(value, code: item.currencyCode)
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
        PhotosPicker(selection: $selection, matching: .images) {
            ZStack {
                if let photoData, let photo = UIImage(data: photoData) {
                    Image(uiImage: photo).resizable().scaledToFit().padding(10)
                } else {
                    VStack(spacing: 9) {
                        Image(systemName: "photo.badge.plus").font(.system(size: 24, weight: .light))
                        Text(appLanguage.text("添加图片")).font(.system(size: 11))
                    }
                    .foregroundStyle(HWTheme.secondaryText)
                }
                if isLoading { ProgressView() }
            }
            .frame(width: 92, height: 90)
            .background(HWTheme.cream.opacity(0.65), in: RoundedRectangle(cornerRadius: 19))
            .overlay(alignment: .bottomTrailing) {
                if photoData != nil {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(HWTheme.freshGreen)
                        .padding(7)
                        .background(HWTheme.cardBackground, in: Circle())
                        .offset(x: 4, y: 4)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(appLanguage.text(photoData == nil ? "添加商品图片" : "更换商品图片"))
        .onChange(of: photoData) { _, data in
            if data == nil { selection = nil }
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

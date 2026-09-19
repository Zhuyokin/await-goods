import Foundation
import WidgetKit
import UIKit
import ImageIO
import CryptoKit

enum WidgetSyncService {
    static func sync(items: [WishItem]) {
        WatchSyncService.shared.sync(items: items)

        let snapshots = items
            .filter { !$0.isTrashed && $0.status == .waiting }
            .sorted { lhs, rhs in
                if lhs.sortIndex == rhs.sortIndex {
                    return lhs.createdAt > rhs.createdAt
                }
                return lhs.sortIndex < rhs.sortIndex
            }
            .map { item in
                WishSnapshot(id: item.id, title: item.title, price: item.price,
                             savedAmount: item.savedAmountValue, sortIndex: item.sortIndex,
                             photoFilename: savePhoto(for: item), groups: groups(for: item))
            }

        let languageCode = UserDefaults.standard.string(forKey: "appLanguage") ?? AppLanguage.zhHans.rawValue
        let previousPhotos = WidgetSnapshotStore.load().compactMap(\.photoFilename)
        WidgetSnapshotStore.save(items: Array(snapshots), languageCode: languageCode)
        if let directory = WidgetSnapshotStore.photoDirectory {
            WidgetSnapshotStore.removeUnusedPhotos(in: directory, previousFilenames: previousPhotos,
                                                   currentFilenames: snapshots.compactMap(\.photoFilename))
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    private static func groups(for item: WishItem) -> [String] {
        let category = item.category.trimmingCharacters(in: .whitespacesAndNewlines)
        var groups = category.isEmpty ? [] : [category]
        #if DEBUG
        if ScreenshotSeedService.isEnabled {
            if ["Hermès", "Louis Vuitton"].contains(category) { groups.insert("包包", at: 0) }
            if category == "Rolex" { groups.insert("腕表", at: 0) }
            if category == "Cars" { groups.insert("汽车", at: 0) }
        }
        #endif
        return groups
    }

    private static func savePhoto(for item: WishItem) -> String? {
        guard let data = item.photoData else { return nil }
        let filename = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined() + ".png"
        guard let url = WidgetSnapshotStore.photoURL(filename: filename) else { return nil }
        if FileManager.default.fileExists(atPath: url.path) { return filename }
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: 360
              ] as CFDictionary),
              let png = UIImage(cgImage: thumbnail).pngData() else { return nil }
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try png.write(to: url, options: .atomic)
            return filename
        } catch {
            return nil
        }
    }
}

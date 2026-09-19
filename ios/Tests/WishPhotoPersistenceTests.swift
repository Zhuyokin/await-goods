import Foundation
import SwiftData

@main
struct WishPhotoPersistenceTests {
    @MainActor
    static func main() throws {
        let container = try ModelContainer(for: WishItem.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        WishStatisticsTests.run()
        let data = Data([0xFF, 0xD8, 0xFF, 0xD9])
        let photoItem = WishItem(title: "With photo", photoData: data)
        container.mainContext.insert(photoItem)
        container.mainContext.insert(WishItem(title: "Without photo"))
        try container.mainContext.save()
        let context = ModelContext(container)
        let loaded = try context.fetch(FetchDescriptor<WishItem>())
        precondition(loaded.first { $0.title == "With photo" }?.photoData == data)
        precondition(loaded.first { $0.title == "Without photo" }?.photoData == nil)
        let legacyJSON = """
        {"id":"00000000-0000-0000-0000-000000000001","title":"Legacy wish","price":100,"sortIndex":0}
        """.data(using: .utf8)!
        let legacy = try JSONDecoder().decode(WishSnapshot.self, from: legacyJSON)
        precondition(legacy.photoFilename == nil)
        precondition(legacy.savedAmount == 0)
        let snapshot = WishSnapshot(id: UUID(), title: "Photo wish", price: 100, savedAmount: 35, sortIndex: 0, photoFilename: "photo.png")
        let restored = try JSONDecoder().decode(WishSnapshot.self, from: JSONEncoder().encode(snapshot))
        precondition(restored == snapshot)
        precondition(restored.savingsProgress == 0.35 && restored.remainingAmount == 65)
        precondition(WidgetSnapshotStore.photoURL(filename: "../photo.png") == nil)
        precondition(legacy.groups.isEmpty)
        let bag = WishSnapshot(id: UUID(), title: "Bag", price: 100, sortIndex: 0, groups: ["包包", "Hermès"])
        let watch = WishSnapshot(id: UUID(), title: "Watch", price: 200, sortIndex: 1, groups: ["腕表", "Rolex"])
        let items = [bag, watch]
        precondition(WidgetContentFilter.select(items, group: "包包").map(\.id) == [bag.id])
        precondition(WidgetContentFilter.select(items, group: "Rolex").map(\.id) == [watch.id])
        precondition(WidgetContentFilter.select(items, group: nil).count == 2)
        precondition(WidgetContentFilter.select(items, group: "Removed").isEmpty)
        precondition(WidgetContentFilter.select(items, group: nil, itemID: UUID()).isEmpty)
        precondition(WidgetContentFilter.select(items, group: "包包", itemID: watch.id).map(\.id) == [watch.id])
        let restoredBag = try JSONDecoder().decode(WishSnapshot.self, from: JSONEncoder().encode(bag))
        precondition(restoredBag.groups == ["包包", "Hermès"])
        try recentTimelinePhotosSurviveSuccessiveSyncs()
        print("Wish photo persistence checks passed")
    }

    private static func recentTimelinePhotosSurviveSuccessiveSyncs() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let expiredDate = Date().addingTimeInterval(-48 * 60 * 60)
        for filename in ["old.png", "current.png", "orphan.png", "other.txt"] {
            let url = directory.appendingPathComponent(filename)
            try Data([1]).write(to: url)
            try FileManager.default.setAttributes([.modificationDate: expiredDate], ofItemAtPath: url.path)
        }

        WidgetSnapshotStore.removeUnusedPhotos(in: directory, previousFilenames: ["old.png"], currentFilenames: ["current.png"])
        precondition(FileManager.default.fileExists(atPath: directory.appendingPathComponent("old.png").path))
        precondition(!FileManager.default.fileExists(atPath: directory.appendingPathComponent("orphan.png").path))

        WidgetSnapshotStore.removeUnusedPhotos(in: directory, previousFilenames: ["current.png"], currentFilenames: ["current.png"])
        precondition(FileManager.default.fileExists(atPath: directory.appendingPathComponent("old.png").path),
                     "Repeated sync must keep photos still referenced by the previous widget timeline")

        try Data([2]).write(to: directory.appendingPathComponent("next.png"))
        WidgetSnapshotStore.removeUnusedPhotos(in: directory, previousFilenames: ["current.png"], currentFilenames: ["next.png"])
        precondition(FileManager.default.fileExists(atPath: directory.appendingPathComponent("old.png").path),
                     "Successive photo changes must preserve recent timeline images")
        WidgetSnapshotStore.removeUnusedPhotos(in: directory, previousFilenames: ["next.png"], currentFilenames: [])
        WidgetSnapshotStore.removeUnusedPhotos(in: directory, previousFilenames: [], currentFilenames: [])
        precondition(FileManager.default.fileExists(atPath: directory.appendingPathComponent("current.png").path),
                     "Empty syncs must preserve recent timeline images")
        precondition(FileManager.default.fileExists(atPath: directory.appendingPathComponent("next.png").path))

        try FileManager.default.setAttributes([.modificationDate: expiredDate], ofItemAtPath: directory.appendingPathComponent("old.png").path)
        WidgetSnapshotStore.removeUnusedPhotos(in: directory, previousFilenames: [], currentFilenames: ["next.png"])
        precondition(!FileManager.default.fileExists(atPath: directory.appendingPathComponent("old.png").path),
                     "Expired unreferenced photos must still be removed")
        precondition(FileManager.default.fileExists(atPath: directory.appendingPathComponent("current.png").path))
        precondition(FileManager.default.fileExists(atPath: directory.appendingPathComponent("other.txt").path))
    }
}

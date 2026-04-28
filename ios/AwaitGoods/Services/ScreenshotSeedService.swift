#if DEBUG
import Foundation
import SwiftData

@MainActor
enum ScreenshotSeedService {
    static let isEnabled = true
    private static let replacesExistingData = true

    static func seedIfNeeded(in container: ModelContainer) {
        guard isEnabled else { return }

        let context = ModelContext(container)
        let descriptor = FetchDescriptor<WishItem>()
        let existingItems = (try? context.fetch(descriptor)) ?? []

        if replacesExistingData {
            existingItems.forEach { context.delete($0) }
        } else if !existingItems.isEmpty {
            return
        }

        let seededItems = screenshotItems()
        seededItems.forEach { context.insert($0) }
        try? context.save()
        WidgetSyncService.sync(items: seededItems)
    }

    private static func screenshotItems() -> [WishItem] {
        let now = Date()
        let day: TimeInterval = 24 * 60 * 60

        return [
            WishItem(
                title: "无线降噪耳机",
                price: 1299,
                linkString: "https://example.com/headphones",
                note: "通勤和专注时都能用，先等手头这副耳机真的不够用了再买。",
                category: "数码",
                priority: .high,
                markColor: .green,
                sortIndex: 0,
                createdAt: now.addingTimeInterval(-8 * day),
                updatedAt: now.addingTimeInterval(-1 * day),
                savedAmount: 860
            ),
            WishItem(
                title: "亚麻通勤托特包",
                price: 680,
                linkString: "https://example.com/tote",
                note: "颜色要耐看，能放电脑和雨伞，不急着下单。",
                category: "衣物",
                priority: .medium,
                markColor: .yellow,
                sortIndex: 1,
                createdAt: now.addingTimeInterval(-7 * day),
                updatedAt: now.addingTimeInterval(-2 * day),
                savedAmount: 240
            ),
            WishItem(
                title: "生日礼物香薰",
                price: 259,
                linkString: "https://example.com/aroma",
                note: "给妈妈的生日礼物，味道选木质调或者白茶。",
                category: "礼物",
                priority: .high,
                markColor: .pink,
                sortIndex: 2,
                createdAt: now.addingTimeInterval(-6 * day),
                updatedAt: now.addingTimeInterval(-1 * day),
                savedAmount: 180
            ),
            WishItem(
                title: "玄关感应灯",
                price: 189,
                linkString: "https://example.com/light",
                note: "晚上回家不用摸黑，确认安装位置后再买。",
                category: "家居",
                priority: .medium,
                markColor: .green,
                sortIndex: 3,
                createdAt: now.addingTimeInterval(-5 * day),
                updatedAt: now.addingTimeInterval(-2 * day),
                savedAmount: 120
            ),
            WishItem(
                title: "羊毛短大衣",
                price: 1680,
                linkString: "https://example.com/coat",
                note: "等换季再看，先确认衣柜里有没有相似款。",
                category: "衣物",
                priority: .high,
                markColor: .gray,
                sortIndex: 4,
                createdAt: now.addingTimeInterval(-12 * day),
                updatedAt: now.addingTimeInterval(-3 * day),
                savedAmount: 620
            ),
            WishItem(
                title: "折叠露营椅",
                price: 329,
                linkString: "https://example.com/chair",
                note: "周末公园和露营都能用，先看使用频率。",
                category: "运动",
                priority: .medium,
                markColor: .none,
                sortIndex: 5,
                createdAt: now.addingTimeInterval(-4 * day),
                updatedAt: now.addingTimeInterval(-1 * day),
                savedAmount: 90
            ),
            WishItem(
                title: "《设计心理学》精装版",
                price: 98,
                linkString: "https://example.com/book",
                note: "想补设计基础，先读完书架上那本再入。",
                category: "书影音",
                priority: .low,
                markColor: .yellow,
                sortIndex: 6,
                createdAt: now.addingTimeInterval(-3 * day),
                updatedAt: now.addingTimeInterval(-1 * day),
                savedAmount: 40
            ),
            WishItem(
                title: "手冲咖啡壶",
                price: 298,
                linkString: "https://example.com/kettle",
                note: "现有水壶还能用，先把咖啡豆喝完。",
                category: "家居",
                priority: .low,
                markColor: .gray,
                sortIndex: 7,
                createdAt: now.addingTimeInterval(-2 * day),
                updatedAt: now,
                savedAmount: 56
            ),
            WishItem(
                title: "日式陶瓷咖啡杯",
                price: 168,
                linkString: "https://example.com/cup",
                note: "已经拥有，大小刚好，适合放在详情页截图。",
                category: "家居",
                priority: .medium,
                status: .bought,
                markColor: .pink,
                sortIndex: 8,
                createdAt: now.addingTimeInterval(-18 * day),
                updatedAt: now.addingTimeInterval(-6 * day),
                savedAmount: 168
            ),
            WishItem(
                title: "轻便旅行拍立得",
                price: 799,
                linkString: "https://example.com/camera",
                note: "使用场景太少，先放下，等真正需要旅行记录时再说。",
                category: "数码",
                priority: .low,
                status: .released,
                markColor: .gray,
                sortIndex: 9,
                createdAt: now.addingTimeInterval(-20 * day),
                updatedAt: now.addingTimeInterval(-4 * day),
                savedAmount: 120
            ),
            WishItem(
                title: "厨房空气炸锅",
                price: 499,
                linkString: "https://example.com/airfryer",
                note: "台面空间不够，暂时不买。",
                category: "家居",
                priority: .medium,
                status: .released,
                markColor: .none,
                sortIndex: 10,
                createdAt: now.addingTimeInterval(-16 * day),
                updatedAt: now.addingTimeInterval(-5 * day),
                savedAmount: 80
            ),
            WishItem(
                title: "月白床品四件套",
                price: 459,
                linkString: "https://example.com/bedding",
                note: "换季时再买，颜色要清爽，材质优先纯棉。",
                category: "家居",
                priority: .medium,
                markColor: .green,
                sortIndex: 11,
                createdAt: now.addingTimeInterval(-1 * day),
                updatedAt: now,
                savedAmount: 210
            )
        ]
    }
}
#endif

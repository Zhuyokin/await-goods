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

        return seedWishes.enumerated().map { index, seed in
            WishItem(
                title: seed.title,
                price: seed.price,
                linkString: seed.linkString,
                note: seed.note,
                category: seed.category,
                priority: seed.priority,
                status: seed.status,
                markColor: seed.markColor,
                sortIndex: index,
                createdAt: now.addingTimeInterval(-Double(index + 1) * day),
                updatedAt: now.addingTimeInterval(-Double(index % 9) * day),
                savedAmount: seed.savedAmount
            )
        }
    }

    private struct SeedWish {
        let title: String
        let price: Double
        let linkString: String
        let note: String
        let category: String
        let priority: WishPriority
        let status: WishItemStatus
        let markColor: MarkColor
        let savedAmount: Double
    }

    private static let seedWishes: [SeedWish] = [
        SeedWish(title: "Louis Vuitton Neverfull MM", price: 2030, linkString: "https://us.louisvuitton.com/eng-us/search/neverfull%20mm", note: "A high-frequency tote for work, travel, and weekend errands. Wait for the exact canvas and interior color.", category: "Luxury Bags", priority: .high, status: .waiting, markColor: .green, savedAmount: 820),
        SeedWish(title: "Louis Vuitton Speedy Bandouliere 25", price: 1890, linkString: "https://us.louisvuitton.com/eng-us/search/speedy%20bandouliere%2025", note: "Classic size, practical strap, and still easy to style after the trend cycle cools down.", category: "Luxury Bags", priority: .high, status: .waiting, markColor: .yellow, savedAmount: 540),
        SeedWish(title: "Louis Vuitton OnTheGo MM", price: 3350, linkString: "https://us.louisvuitton.com/eng-us/search/onthego%20mm", note: "Fits a laptop and daily pouch setup. Compare with Neverfull before committing.", category: "Luxury Bags", priority: .medium, status: .waiting, markColor: .green, savedAmount: 1180),
        SeedWish(title: "Louis Vuitton Alma BB", price: 1760, linkString: "https://us.louisvuitton.com/eng-us/search/alma%20bb", note: "Polished mini top-handle shape for dinners and city days.", category: "Luxury Bags", priority: .medium, status: .waiting, markColor: .pink, savedAmount: 430),
        SeedWish(title: "Louis Vuitton Pochette Metis", price: 2570, linkString: "https://us.louisvuitton.com/eng-us/search/pochette%20metis", note: "A compact crossbody with real structure. Watch resale pricing before buying new.", category: "Luxury Bags", priority: .high, status: .waiting, markColor: .gray, savedAmount: 980),
        SeedWish(title: "Hermes Birkin 25", price: 12000, linkString: "https://www.hermes.com/us/en/search/?s=birkin%2025", note: "Wishlist dream piece. Keep this as a long-term luxury target, not an impulse purchase.", category: "Luxury Bags", priority: .high, status: .waiting, markColor: .pink, savedAmount: 3200),
        SeedWish(title: "Hermes Kelly 25", price: 11500, linkString: "https://www.hermes.com/us/en/search/?s=kelly%2025", note: "Structured, elegant, and very hard to source. Only worth it in a color that works year-round.", category: "Luxury Bags", priority: .high, status: .waiting, markColor: .green, savedAmount: 2750),
        SeedWish(title: "Hermes Constance 18", price: 8900, linkString: "https://www.hermes.com/us/en/search/?s=constance%2018", note: "Small enough for evenings, iconic enough for daily rotation if the leather is durable.", category: "Luxury Bags", priority: .medium, status: .waiting, markColor: .yellow, savedAmount: 1980),
        SeedWish(title: "Hermes Evelyne 29", price: 4200, linkString: "https://www.hermes.com/us/en/search/?s=evelyne%2029", note: "More casual than the quota bags and genuinely useful for hands-free days.", category: "Luxury Bags", priority: .medium, status: .waiting, markColor: .none, savedAmount: 1260),
        SeedWish(title: "Hermes Oran Sandals", price: 760, linkString: "https://www.hermes.com/us/en/search/?s=oran%20sandals", note: "Summer staple, but only if the fit is comfortable enough for long walks.", category: "Designer Shoes", priority: .low, status: .waiting, markColor: .yellow, savedAmount: 250),
        SeedWish(title: "Chanel Classic Flap Medium", price: 10800, linkString: "https://www.chanel.com/us/fashion/search/?q=classic%20flap", note: "The benchmark quilted bag. Recheck current price and lambskin durability before deciding.", category: "Luxury Bags", priority: .high, status: .waiting, markColor: .pink, savedAmount: 2800),
        SeedWish(title: "Chanel Boy Bag Small", price: 6600, linkString: "https://www.chanel.com/us/fashion/search/?q=boy%20bag", note: "Edgier than the classic flap and better for casual outfits.", category: "Luxury Bags", priority: .medium, status: .waiting, markColor: .gray, savedAmount: 1400),
        SeedWish(title: "Chanel Coco Handle", price: 6800, linkString: "https://www.chanel.com/us/fashion/search/?q=coco%20handle", note: "Top handle plus strap makes it versatile. Wait for the right hardware tone.", category: "Luxury Bags", priority: .medium, status: .waiting, markColor: .green, savedAmount: 1720),
        SeedWish(title: "Chanel Wallet on Chain", price: 3350, linkString: "https://www.chanel.com/us/fashion/search/?q=wallet%20on%20chain", note: "A lighter entry point for evenings, travel, and minimal carry days.", category: "Luxury Bags", priority: .medium, status: .waiting, markColor: .yellow, savedAmount: 760),
        SeedWish(title: "Chanel No. 5 Eau de Parfum", price: 172, linkString: "https://www.chanel.com/us/fragrance/search/?q=no%205", note: "Iconic fragrance for the vanity, but sample it again before buying a full bottle.", category: "Beauty", priority: .low, status: .waiting, markColor: .pink, savedAmount: 90),
        SeedWish(title: "Chanel Slingback Pumps", price: 1150, linkString: "https://www.chanel.com/us/fashion/search/?q=slingback", note: "Polished heel for work and events. Comfort test matters more than the logo.", category: "Designer Shoes", priority: .medium, status: .waiting, markColor: .none, savedAmount: 380),
        SeedWish(title: "Chanel Tweed Jacket", price: 8200, linkString: "https://www.chanel.com/us/fashion/search/?q=tweed%20jacket", note: "Statement wardrobe piece. Only buy if it layers well with existing basics.", category: "Fashion", priority: .low, status: .released, markColor: .gray, savedAmount: 600),
        SeedWish(title: "Rolex Submariner Date", price: 10250, linkString: "https://www.rolex.com/watches/submariner", note: "Classic sports watch with strong demand. Track availability and premium before moving forward.", category: "Watches", priority: .high, status: .waiting, markColor: .green, savedAmount: 3100),
        SeedWish(title: "Rolex Datejust 36", price: 8350, linkString: "https://www.rolex.com/watches/datejust", note: "Everyday luxury watch candidate. Compare dial colors in person.", category: "Watches", priority: .high, status: .waiting, markColor: .yellow, savedAmount: 2400),
        SeedWish(title: "Rolex Lady-Datejust 28", price: 7600, linkString: "https://www.rolex.com/watches/lady-datejust", note: "Smaller profile and jewelry-like presence for formal daily wear.", category: "Watches", priority: .medium, status: .waiting, markColor: .pink, savedAmount: 1740),
        SeedWish(title: "Rolex GMT-Master II", price: 10800, linkString: "https://www.rolex.com/watches/gmt-master-ii", note: "Travel watch icon. Keep as a long-term target until the market cools.", category: "Watches", priority: .medium, status: .waiting, markColor: .gray, savedAmount: 2100),
        SeedWish(title: "Rolex Oyster Perpetual 36", price: 6100, linkString: "https://www.rolex.com/watches/oyster-perpetual", note: "Clean dial, easy size, and more understated than most hype pieces.", category: "Watches", priority: .medium, status: .waiting, markColor: .none, savedAmount: 1880),
        SeedWish(title: "Cartier Love Bracelet", price: 7350, linkString: "https://www.cartier.com/en-us/search?q=love%20bracelet", note: "Fine jewelry staple. Confirm sizing and metal tone before locking in.", category: "Jewelry", priority: .high, status: .waiting, markColor: .pink, savedAmount: 2560),
        SeedWish(title: "Van Cleef & Arpels Vintage Alhambra Necklace", price: 3150, linkString: "https://www.vancleefarpels.com/us/en/search.html?q=vintage%20alhambra", note: "Popular everyday necklace. Think through stone durability and color matching.", category: "Jewelry", priority: .high, status: .waiting, markColor: .green, savedAmount: 980),
        SeedWish(title: "Tiffany Lock Bangle", price: 7300, linkString: "https://www.tiffany.com/search/?q=lock%20bangle", note: "Modern bracelet with strong styling impact. Try the clasp in store first.", category: "Jewelry", priority: .medium, status: .waiting, markColor: .yellow, savedAmount: 1320),
        SeedWish(title: "Dior Book Tote", price: 3500, linkString: "https://www.dior.com/en_us/search?q=book%20tote", note: "Travel and work tote with a bold pattern. Make sure it is not too seasonal.", category: "Luxury Bags", priority: .medium, status: .waiting, markColor: .gray, savedAmount: 960),
        SeedWish(title: "Dior Lady Dior Medium", price: 6500, linkString: "https://www.dior.com/en_us/search?q=lady%20dior", note: "Elegant top-handle option for formal outfits and events.", category: "Luxury Bags", priority: .high, status: .waiting, markColor: .pink, savedAmount: 1520),
        SeedWish(title: "Prada Re-Edition 2005", price: 1950, linkString: "https://www.prada.com/us/en/search.html?search=Re-Edition%202005", note: "Lightweight nylon shoulder bag for errands, travel, and casual outfits.", category: "Luxury Bags", priority: .medium, status: .bought, markColor: .green, savedAmount: 1950),
        SeedWish(title: "Miu Miu Matelasse Shoulder Bag", price: 2950, linkString: "https://www.miumiu.com/us/en/search.html?search=matelasse%20bag", note: "Feminine texture and strong fashion signal. Check if it still feels wearable next month.", category: "Luxury Bags", priority: .medium, status: .waiting, markColor: .yellow, savedAmount: 740),
        SeedWish(title: "Celine Triomphe Shoulder Bag", price: 3950, linkString: "https://www.celine.com/en-us/search?q=triomphe", note: "Quiet but recognizable. Best if the size works for phone, wallet, keys, and lipstick.", category: "Luxury Bags", priority: .high, status: .waiting, markColor: .none, savedAmount: 1460),
        SeedWish(title: "Bottega Veneta Andiamo Small", price: 4100, linkString: "https://www.bottegaveneta.com/en-us/search?q=andiamo", note: "Woven leather with a polished silhouette. Compare small and medium before saving more.", category: "Luxury Bags", priority: .medium, status: .waiting, markColor: .green, savedAmount: 1040),
        SeedWish(title: "Gucci Jackie 1961 Small", price: 3200, linkString: "https://www.gucci.com/us/en/search?search-cat=header&q=jackie%201961", note: "Retro shoulder bag that still works with simple outfits.", category: "Luxury Bags", priority: .medium, status: .waiting, markColor: .gray, savedAmount: 890),
        SeedWish(title: "Saint Laurent Le 5 a 7", price: 2400, linkString: "https://www.ysl.com/en-us/search?q=le%205%20a%207", note: "Sleek city bag for evenings. Confirm it is not too small for daily essentials.", category: "Luxury Bags", priority: .medium, status: .waiting, markColor: .pink, savedAmount: 610),
        SeedWish(title: "Loewe Puzzle Bag Small", price: 3450, linkString: "https://www.loewe.com/usa/en/search?q=puzzle%20bag", note: "Architectural shape and practical crossbody carry. Watch color availability.", category: "Luxury Bags", priority: .high, status: .waiting, markColor: .yellow, savedAmount: 1250),
        SeedWish(title: "The Row Margaux 10 Bag", price: 4390, linkString: "https://www.therow.com/search?q=margaux", note: "Quiet luxury work bag candidate. Only worth it if the structure feels easy to use.", category: "Luxury Bags", priority: .medium, status: .released, markColor: .gray, savedAmount: 500),
        SeedWish(title: "Dyson Airwrap Multi-Styler", price: 599, linkString: "https://www.dyson.com/hair-care/hair-stylers/airwrap", note: "High-frequency beauty tool if it actually replaces salon blowouts.", category: "Beauty Tech", priority: .high, status: .waiting, markColor: .green, savedAmount: 360),
        SeedWish(title: "La Mer Moisturizing Cream", price: 380, linkString: "https://www.cremedelamer.com/products/5834/moisturizers/creme-de-la-mer", note: "Luxury skincare classic. Buy only after finishing the current moisturizer.", category: "Beauty", priority: .low, status: .waiting, markColor: .pink, savedAmount: 150),
        SeedWish(title: "SK-II Facial Treatment Essence", price: 245, linkString: "https://www.sk-ii.com/product/facial-treatment-essence", note: "Cult favorite essence. Wait for a set or travel-size bundle.", category: "Beauty", priority: .medium, status: .waiting, markColor: .yellow, savedAmount: 120),
        SeedWish(title: "Jo Malone English Pear & Freesia", price: 165, linkString: "https://www.jomalone.com/search?q=english%20pear%20freesia", note: "Easy daily fragrance. Test longevity before buying the full size.", category: "Beauty", priority: .low, status: .bought, markColor: .none, savedAmount: 165),
        SeedWish(title: "Lululemon Align High-Rise Pant", price: 98, linkString: "https://shop.lululemon.com/search?Ntt=align%20high-rise%20pant", note: "High-frequency activewear for errands, yoga, and travel days.", category: "Fashion", priority: .medium, status: .waiting, markColor: .green, savedAmount: 48),
        SeedWish(title: "Alo Yoga Airlift Legging", price: 128, linkString: "https://www.aloyoga.com/search?q=airlift%20legging", note: "Sleek workout legging. Compare fabric feel with Lululemon before adding another pair.", category: "Fashion", priority: .low, status: .waiting, markColor: .gray, savedAmount: 45),
        SeedWish(title: "Reformation Silk Dress", price: 298, linkString: "https://www.thereformation.com/search?q=silk%20dress", note: "Event-ready dress with a feminine shape. Check if it covers more than one occasion.", category: "Fashion", priority: .medium, status: .waiting, markColor: .pink, savedAmount: 130),
        SeedWish(title: "Aritzia Super Puff Shorty", price: 250, linkString: "https://www.aritzia.com/us/en/search?q=super%20puff%20shorty", note: "Winter staple candidate. Wait for the right color and sale timing.", category: "Fashion", priority: .medium, status: .waiting, markColor: .yellow, savedAmount: 90),
        SeedWish(title: "Apple iPhone 16 Pro", price: 999, linkString: "https://www.apple.com/iphone-16-pro/", note: "Popular Apple upgrade target. Keep current phone until battery or camera truly feels limiting.", category: "Apple", priority: .high, status: .waiting, markColor: .green, savedAmount: 520),
        SeedWish(title: "Apple MacBook Air 13-inch", price: 1099, linkString: "https://www.apple.com/macbook-air/", note: "Light work machine for writing, browsing, and travel. Compare RAM options first.", category: "Apple", priority: .high, status: .waiting, markColor: .gray, savedAmount: 680),
        SeedWish(title: "Apple iPad Pro 11-inch", price: 999, linkString: "https://www.apple.com/ipad-pro/", note: "Great for reading, planning, and sketching, but only if it will not duplicate the MacBook.", category: "Apple", priority: .medium, status: .waiting, markColor: .yellow, savedAmount: 410),
        SeedWish(title: "Apple Watch Series 10", price: 399, linkString: "https://www.apple.com/apple-watch-series-10/", note: "Health and notification upgrade. Keep if daily fitness tracking becomes consistent.", category: "Apple", priority: .medium, status: .waiting, markColor: .green, savedAmount: 210),
        SeedWish(title: "AirPods Pro 2", price: 249, linkString: "https://www.apple.com/airpods-pro/", note: "High-frequency commute and focus item. Replace only when current earbuds fail.", category: "Apple", priority: .medium, status: .bought, markColor: .none, savedAmount: 249),
        SeedWish(title: "Apple Vision Pro", price: 3499, linkString: "https://www.apple.com/apple-vision-pro/", note: "Curiosity item, not urgent. Try a demo again before making it a real target.", category: "Apple", priority: .low, status: .released, markColor: .gray, savedAmount: 300),
        SeedWish(title: "Kindle Paperwhite Signature Edition", price: 190, linkString: "https://www.amazon.com/s?k=Kindle+Paperwhite+Signature+Edition", note: "Reading upgrade with warm light and waterproofing. Buy after finishing the current book stack.", category: "Tech", priority: .low, status: .waiting, markColor: .green, savedAmount: 80)
    ]
}
#endif

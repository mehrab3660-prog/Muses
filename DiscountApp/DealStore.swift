import Foundation
import Combine

@MainActor
final class DealStore: ObservableObject {
    @Published var deals: [Deal] = []
    @Published var favoriteIds: Set<UUID> = []
    @Published var customSites: [CustomSite] = []
    @Published var watchKeywords: [String] = []
    @Published var searchText: String = ""
    @Published var selectedCategory: DealCategory = .all
    @Published var selectedStoreId: String = "all"
    @Published var minDiscount: Int = 0
    @Published var showFavoritesOnly: Bool = false

    private let favoritesKey = "takhfifyab.favorites"
    private let sitesKey = "takhfifyab.customSites"
    private let watchKey = "takhfifyab.watchKeywords"

    init() {
        deals = Self.sampleDeals
        loadPersisted()
    }

    // MARK: - Persistence (UserDefaults)
    private func loadPersisted() {
        if let data = UserDefaults.standard.data(forKey: favoritesKey),
           let ids = try? JSONDecoder().decode([UUID].self, from: data) {
            favoriteIds = Set(ids)
        }
        if let data = UserDefaults.standard.data(forKey: sitesKey),
           let sites = try? JSONDecoder().decode([CustomSite].self, from: data) {
            customSites = sites
        }
        if let data = UserDefaults.standard.data(forKey: watchKey),
           let words = try? JSONDecoder().decode([String].self, from: data) {
            watchKeywords = words
        }
    }

    private func saveFavorites() {
        if let data = try? JSONEncoder().encode(Array(favoriteIds)) {
            UserDefaults.standard.set(data, forKey: favoritesKey)
        }
    }

    private func saveSites() {
        if let data = try? JSONEncoder().encode(customSites) {
            UserDefaults.standard.set(data, forKey: sitesKey)
        }
    }

    private func saveWatch() {
        if let data = try? JSONEncoder().encode(watchKeywords) {
            UserDefaults.standard.set(data, forKey: watchKey)
        }
    }

    // MARK: - Favorites
    func toggleFavorite(_ deal: Deal) {
        if favoriteIds.contains(deal.id) { favoriteIds.remove(deal.id) }
        else { favoriteIds.insert(deal.id) }
        saveFavorites()
    }

    func isFavorite(_ deal: Deal) -> Bool { favoriteIds.contains(deal.id) }

    // MARK: - Custom sites ("سایت‌های من")
    func addCustomSite(name: String, url: String) {
        let site = CustomSite(name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                              url: url.trimmingCharacters(in: .whitespacesAndNewlines))
        guard !site.name.isEmpty, !site.url.isEmpty else { return }
        customSites.append(site)
        saveSites()
    }

    func deleteCustomSite(at offsets: IndexSet) {
        customSites.remove(atOffsets: offsets)
        saveSites()
    }

    func deleteCustomSite(_ site: CustomSite) {
        customSites.removeAll { $0.id == site.id }
        saveSites()
    }

    // MARK: - Watch keywords
    func addWatchKeyword(_ word: String) {
        let w = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !w.isEmpty, !watchKeywords.contains(w) else { return }
        watchKeywords.append(w)
        saveWatch()
    }

    func removeWatchKeyword(_ word: String) {
        watchKeywords.removeAll { $0 == word }
        saveWatch()
    }

    // MARK: - Manual deal
    func addDeal(title: String, storeId: String, category: DealCategory,
                 oldPrice: Int, newPrice: Int, code: String?, url: String) {
        let deal = Deal(id: UUID(), title: title, storeId: storeId, category: category,
                        oldPrice: oldPrice, newPrice: newPrice,
                        code: code?.isEmpty == true ? nil : code,
                        expiryDays: 3, url: url.isEmpty ? "https://www.digikala.com" : url,
                        isFeatured: false)
        deals.insert(deal, at: 0)
    }

    // MARK: - Filtering
    var filteredDeals: [Deal] {
        deals.filter { deal in
            if showFavoritesOnly && !favoriteIds.contains(deal.id) { return false }
            if selectedCategory != .all && deal.category != selectedCategory { return false }
            if selectedStoreId != "all" && deal.storeId != selectedStoreId { return false }
            if deal.discountPercent < minDiscount { return false }
            if !searchText.isEmpty {
                let q = searchText
                if !deal.title.contains(q) && !deal.storeName.contains(q) && !(deal.code?.contains(q) ?? false) {
                    return false
                }
            }
            return true
        }
        .sorted { $0.discountPercent > $1.discountPercent }
    }

    var featuredDeals: [Deal] { deals.filter { $0.isFeatured } }
    var dealOfTheDay: Deal? { deals.max(by: { $0.discountPercent < $1.discountPercent }) }
    var watchedDeals: [Deal] {
        guard !watchKeywords.isEmpty else { return [] }
        return deals.filter { deal in watchKeywords.contains { deal.title.contains($0) } }
    }

    // MARK: - Sample data (24 deals)
    static let sampleDeals: [Deal] = [
        Deal(id: UUID(), title: "گوشی موبایل سامسونگ Galaxy A55 ظرفیت ۲۵۶ گیگابایت", storeId: "digikala", category: .digital, oldPrice: 24900000, newPrice: 19900000, code: nil, expiryDays: 2, url: "https://www.digikala.com", isFeatured: true),
        Deal(id: UUID(), title: "هدفون بی‌سیم انکر Soundcore Life P3", storeId: "digikala", category: .digital, oldPrice: 4200000, newPrice: 2890000, code: "ANKER30", expiryDays: 1, url: "https://www.digikala.com", isFeatured: true),
        Deal(id: UUID(), title: "یخچال فریزر اسنوا ۲۷ فوت مدل S8-2275", storeId: "snowa", category: .homeAppliance, oldPrice: 68500000, newPrice: 54900000, code: nil, expiryDays: 4, url: "https://www.snowa.ir", isFeatured: true),
        Deal(id: UUID(), title: "تلویزیون ال‌ای‌دی دوو ۵۵ اینچ هوشمند 4K", storeId: "daewoo", category: .homeAppliance, oldPrice: 32500000, newPrice: 24900000, code: "DAEWOO10", expiryDays: 3, url: "https://www.daewoo.ir", isFeatured: true),
        Deal(id: UUID(), title: "ماشین لباسشویی اسنوا ۸ کیلوگرم مدل SWM-845", storeId: "technolife", category: .homeAppliance, oldPrice: 29800000, newPrice: 22900000, code: nil, expiryDays: 5, url: "https://www.technolife.ir", isFeatured: false),
        Deal(id: UUID(), title: "جاروبرقی دوو ۲۰۰۰ وات مدل DVC-2000", storeId: "entekhab", category: .homeAppliance, oldPrice: 8900000, newPrice: 6400000, code: nil, expiryDays: 2, url: "https://www.entekhabcenter.com", isFeatured: false),
        Deal(id: UUID(), title: "سرخ‌کن بدون روغن فیلیپس ۴٫۱ لیتر", storeId: "technolife", category: .homeAppliance, oldPrice: 12500000, newPrice: 8900000, code: "TECH15", expiryDays: 6, url: "https://www.technolife.ir", isFeatured: true),
        Deal(id: UUID(), title: "کفش رانینگ نایک Air Zoom مردانه", storeId: "digikala", category: .fashion, oldPrice: 6800000, newPrice: 4200000, code: nil, expiryDays: 3, url: "https://www.digikala.com", isFeatured: false),
        Deal(id: UUID(), title: "کت تک مردانه بهاره", storeId: "basalam", category: .fashion, oldPrice: 2950000, newPrice: 1790000, code: "BSL40", expiryDays: 4, url: "https://basalam.com", isFeatured: false),
        Deal(id: UUID(), title: "ست ۳ تکه لباس بچگانه نخی", storeId: "snappshop", category: .fashion, oldPrice: 1450000, newPrice: 890000, code: nil, expiryDays: 2, url: "https://shop.snapp.ir", isFeatured: false),
        Deal(id: UUID(), title: "ساعت هوشمند شیائومی Watch S1", storeId: "digikala", category: .digital, oldPrice: 5900000, newPrice: 3900000, code: nil, expiryDays: 1, url: "https://www.digikala.com", isFeatured: true),
        Deal(id: UUID(), title: "لپ‌تاپ لنوو IdeaPad 1 پردازنده Ryzen 5", storeId: "technolife", category: .digital, oldPrice: 38900000, newPrice: 31900000, code: nil, expiryDays: 7, url: "https://www.technolife.ir", isFeatured: false),
        Deal(id: UUID(), title: "پاوربانک انکر ۲۰۰۰۰ میلی‌آمپر", storeId: "entekhab", category: .digital, oldPrice: 2450000, newPrice: 1690000, code: "POWER20", expiryDays: 3, url: "https://www.entekhabcenter.com", isFeatured: false),
        Deal(id: UUID(), title: "سبد خرید سوپرمارکتی هفته — تا ۳۰٪ تخفیف", storeId: "snappmarket", category: .supermarket, oldPrice: 1200000, newPrice: 840000, code: "MARKET30", expiryDays: 1, url: "https://snapp.market", isFeatured: true),
        Deal(id: UUID(), title: "برنج طارم هاشمی ۱۰ کیلویی", storeId: "okala", category: .supermarket, oldPrice: 1450000, newPrice: 1090000, code: nil, expiryDays: 2, url: "https://okala.com", isFeatured: false),
        Deal(id: UUID(), title: "روغن آفتابگردان ۳ لیتری", storeId: "okala", category: .supermarket, oldPrice: 420000, newPrice: 299000, code: nil, expiryDays: 5, url: "https://okala.com", isFeatured: false),
        Deal(id: UUID(), title: "کرم مرطوب‌کننده لاروش پوزای ۵۰ میل", storeId: "khanumi", category: .beauty, oldPrice: 1850000, newPrice: 1190000, code: "KHANUMI25", expiryDays: 3, url: "https://www.khanumi.com", isFeatured: true),
        Deal(id: UUID(), title: "سرم ویتامین C گارنیر ۳۰ میل", storeId: "khanumi", category: .beauty, oldPrice: 980000, newPrice: 590000, code: nil, expiryDays: 2, url: "https://www.khanumi.com", isFeatured: false),
        Deal(id: UUID(), title: "عطر ادکلن لانکوم La Vie Est Belle", storeId: "khanumi", category: .beauty, oldPrice: 7900000, newPrice: 5490000, code: nil, expiryDays: 6, url: "https://www.khanumi.com", isFeatured: false),
        Deal(id: UUID(), title: "گردنبند طلا ۱۸ عیار با آویز قلب", storeId: "digikala", category: .gold, oldPrice: 18500000, newPrice: 14900000, code: nil, expiryDays: 4, url: "https://www.digikala.com", isFeatured: false),
        Deal(id: UUID(), title: "مایکروویو دوو ۲۸ لیتر", storeId: "daewoo", category: .homeAppliance, oldPrice: 11500000, newPrice: 8900000, code: nil, expiryDays: 3, url: "https://www.daewoo.ir", isFeatured: false),
        Deal(id: UUID(), title: "قهوه‌ساز نسپرسو مدل Essenza Mini", storeId: "snowa", category: .homeAppliance, oldPrice: 9800000, newPrice: 7200000, code: "SNOWA15", expiryDays: 5, url: "https://www.snowa.ir", isFeatured: false),
        Deal(id: UUID(), title: "اسپیکر بلوتوثی JBL Flip 6", storeId: "digikala", category: .digital, oldPrice: 6900000, newPrice: 4900000, code: nil, expiryDays: 2, url: "https://www.digikala.com", isFeatured: false),
        Deal(id: UUID(), title: "پک ۶ عددی شامپو و نرم‌کننده", storeId: "snappmarket", category: .supermarket, oldPrice: 890000, newPrice: 540000, code: "SNAPP20", expiryDays: 1, url: "https://snapp.market", isFeatured: false)
    ]
}

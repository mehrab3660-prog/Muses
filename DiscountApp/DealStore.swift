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
    @Published var lastUpdated: Date = Date()
    @Published var isRefreshing: Bool = false
    @Published var justRefreshed: Bool = false

    var refreshText: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fa_IR")
        f.dateFormat = "HH:mm"
        return "آخرین به‌روزرسانی: " + f.string(from: lastUpdated)
    }

    /// Pull-to-refresh / toolbar refresh. Re-orders the current deals
    /// (preserving their IDs, so favorites survive) and stamps the time.
    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        justRefreshed = false
        try? await Task.sleep(nanoseconds: 800_000_000)
        deals.shuffle()
        deals.sort { $0.discountPercent > $1.discountPercent }
        lastUpdated = Date()
        isRefreshing = false
        justRefreshed = true
    }

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
                        expiryDays: 3, url: url.isEmpty ? "https://www.digikala.com/search/?q=" + (title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") : url,
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
        Deal(id: UUID(), title: "گوشی موبایل سامسونگ Galaxy A55 ظرفیت ۲۵۶ گیگابایت", storeId: "digikala", category: .digital, oldPrice: 24900000, newPrice: 19900000, code: nil, expiryDays: 2, url: "https://www.digikala.com/search/?q=Galaxy%20A55", imageURL: "https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=800&q=80&auto=format&fit=crop", isFeatured: true),
        Deal(id: UUID(), title: "هدفون بی‌سیم انکر Soundcore Life P3", storeId: "digikala", category: .digital, oldPrice: 4200000, newPrice: 2890000, code: "ANKER30", expiryDays: 1, url: "https://www.digikala.com/search/?q=Soundcore%20Life%20P3", imageURL: "https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=800&q=80&auto=format&fit=crop", isFeatured: true),
        Deal(id: UUID(), title: "یخچال فریزر اسنوا ۲۷ فوت مدل S8-2275", storeId: "snowa", category: .homeAppliance, oldPrice: 68500000, newPrice: 54900000, code: nil, expiryDays: 4, url: "https://www.snowa.ir/search?q=%DB%8C%D8%AE%DA%86%D8%A7%D9%84%20%D9%81%D8%B1%DB%8C%D8%B2%D8%B1", imageURL: "https://images.unsplash.com/photo-1571175443880-49e1d25b2bc5?w=800&q=80&auto=format&fit=crop", isFeatured: true),
        Deal(id: UUID(), title: "تلویزیون ال‌ای‌دی دوو ۵۵ اینچ هوشمند 4K", storeId: "daewoo", category: .homeAppliance, oldPrice: 32500000, newPrice: 24900000, code: "DAEWOO10", expiryDays: 3, url: "https://www.daewoo.ir/search?q=%D8%AA%D9%84%D9%88%DB%8C%D8%B2%DB%8C%D9%88%D9%86%2055", imageURL: "https://images.unsplash.com/photo-1593359677879-a4bb92f829d1?w=800&q=80&auto=format&fit=crop", isFeatured: true),
        Deal(id: UUID(), title: "ماشین لباسشویی اسنوا ۸ کیلوگرم مدل SWM-845", storeId: "technolife", category: .homeAppliance, oldPrice: 29800000, newPrice: 22900000, code: nil, expiryDays: 5, url: "https://www.technolife.ir/search?q=%D9%85%D8%A7%D8%B4%DB%8C%D9%86%20%D9%84%D8%A8%D8%A7%D8%B3%D8%B4%D9%88%DB%8C%DB%8C", imageURL: "https://images.unsplash.com/photo-1626806787461-102c1bfaaea1?w=800&q=80&auto=format&fit=crop", isFeatured: false),
        Deal(id: UUID(), title: "جاروبرقی دوو ۲۰۰۰ وات مدل DVC-2000", storeId: "entekhab", category: .homeAppliance, oldPrice: 8900000, newPrice: 6400000, code: nil, expiryDays: 2, url: "https://www.entekhabcenter.com/search?q=%D8%AC%D8%A7%D8%B1%D9%88%D8%A8%D8%B1%D9%82%DB%8C", imageURL: "https://images.unsplash.com/photo-1558317374-067fb5f30001?w=800&q=80&auto=format&fit=crop", isFeatured: false),
        Deal(id: UUID(), title: "سرخ‌کن بدون روغن فیلیپس ۴٫۱ لیتر", storeId: "technolife", category: .homeAppliance, oldPrice: 12500000, newPrice: 8900000, code: "TECH15", expiryDays: 6, url: "https://www.technolife.ir/search?q=%D8%B3%D8%B1%D8%AE%20%DA%A9%D9%86%20%D9%81%DB%8C%D9%84%DB%8C%D9%BE%D8%B3", imageURL: "https://images.unsplash.com/photo-1585515320310-259814833e62?w=800&q=80&auto=format&fit=crop", isFeatured: true),
        Deal(id: UUID(), title: "کفش رانینگ نایک Air Zoom مردانه", storeId: "digikala", category: .fashion, oldPrice: 6800000, newPrice: 4200000, code: nil, expiryDays: 3, url: "https://www.digikala.com/search/?q=Nike%20Air%20Zoom", imageURL: "https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800&q=80&auto=format&fit=crop", isFeatured: false),
        Deal(id: UUID(), title: "کت تک مردانه بهاره", storeId: "basalam", category: .fashion, oldPrice: 2950000, newPrice: 1790000, code: "BSL40", expiryDays: 4, url: "https://basalam.com/search?q=%DA%A9%D8%AA%20%D9%85%D8%B1%D8%AF%D8%A7%D9%86%D9%87", imageURL: "https://images.unsplash.com/photo-1591047139829-d91aecb6caea?w=800&q=80&auto=format&fit=crop", isFeatured: false),
        Deal(id: UUID(), title: "ست ۳ تکه لباس بچگانه نخی", storeId: "snappshop", category: .fashion, oldPrice: 1450000, newPrice: 890000, code: nil, expiryDays: 2, url: "https://shop.snapp.ir/search?q=%D9%84%D8%A8%D8%A7%D8%B3%20%D8%A8%DA%86%DA%AF%D8%A7%D9%86%D9%87", imageURL: "https://images.unsplash.com/photo-1519238263530-99bdd11df2ea?w=800&q=80&auto=format&fit=crop", isFeatured: false),
        Deal(id: UUID(), title: "ساعت هوشمند شیائومی Watch S1", storeId: "digikala", category: .digital, oldPrice: 5900000, newPrice: 3900000, code: nil, expiryDays: 1, url: "https://www.digikala.com/search/?q=Xiaomi%20Watch%20S1", imageURL: "https://images.unsplash.com/photo-1546868871-7041f2a55e12?w=800&q=80&auto=format&fit=crop", isFeatured: true),
        Deal(id: UUID(), title: "لپ‌تاپ لنوو IdeaPad 1 پردازنده Ryzen 5", storeId: "technolife", category: .digital, oldPrice: 38900000, newPrice: 31900000, code: nil, expiryDays: 7, url: "https://www.technolife.ir/search?q=%D9%84%D9%BE%20%D8%AA%D8%A7%D9%BE%20%D9%84%D9%86%D9%88%D9%88%20IdeaPad", imageURL: "https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=800&q=80&auto=format&fit=crop", isFeatured: false),
        Deal(id: UUID(), title: "پاوربانک انکر ۲۰۰۰۰ میلی‌آمپر", storeId: "entekhab", category: .digital, oldPrice: 2450000, newPrice: 1690000, code: "POWER20", expiryDays: 3, url: "https://www.entekhabcenter.com/search?q=%D9%BE%D8%A7%D9%88%D8%B1%D8%A8%D8%A7%D9%86%DA%A9%20%D8%A7%D9%86%DA%A9%D8%B1", imageURL: "https://images.unsplash.com/photo-1609091839311-d5365f9ff1c5?w=800&q=80&auto=format&fit=crop", isFeatured: false),
        Deal(id: UUID(), title: "سبد خرید سوپرمارکتی هفته — تا ۳۰٪ تخفیف", storeId: "snappmarket", category: .supermarket, oldPrice: 1200000, newPrice: 840000, code: "MARKET30", expiryDays: 1, url: "https://snapp.market/search?q=%D8%AA%D8%AE%D9%81%DB%8C%D9%81", imageURL: "https://images.unsplash.com/photo-1542838132-92c53300491e?w=800&q=80&auto=format&fit=crop", isFeatured: true),
        Deal(id: UUID(), title: "برنج طارم هاشمی ۱۰ کیلویی", storeId: "okala", category: .supermarket, oldPrice: 1450000, newPrice: 1090000, code: nil, expiryDays: 2, url: "https://okala.com/search?q=%D8%A8%D8%B1%D9%86%D8%AC%20%D8%B7%D8%A7%D8%B1%D9%85", imageURL: "https://images.unsplash.com/photo-1586201375761-83865001e31c?w=800&q=80&auto=format&fit=crop", isFeatured: false),
        Deal(id: UUID(), title: "روغن آفتابگردان ۳ لیتری", storeId: "okala", category: .supermarket, oldPrice: 420000, newPrice: 299000, code: nil, expiryDays: 5, url: "https://okala.com/search?q=%D8%B1%D9%88%D8%BA%D9%86%20%D8%A2%D9%81%D8%AA%D8%A7%D8%A8%DA%AF%D8%B1%D8%AF%D8%A7%D9%86", imageURL: "https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=800&q=80&auto=format&fit=crop", isFeatured: false),
        Deal(id: UUID(), title: "کرم مرطوب‌کننده لاروش پوزای ۵۰ میل", storeId: "khanumi", category: .beauty, oldPrice: 1850000, newPrice: 1190000, code: "KHANUMI25", expiryDays: 3, url: "https://www.khanumi.com/search?q=La%20Roche%20Posay", imageURL: "https://images.unsplash.com/photo-1556228720-195a672e8a03?w=800&q=80&auto=format&fit=crop", isFeatured: true),
        Deal(id: UUID(), title: "سرم ویتامین C گارنیر ۳۰ میل", storeId: "khanumi", category: .beauty, oldPrice: 980000, newPrice: 590000, code: nil, expiryDays: 2, url: "https://www.khanumi.com/search?q=Garnier%20Vitamin%20C", imageURL: "https://images.unsplash.com/photo-1620916566398-39f1143ab7be?w=800&q=80&auto=format&fit=crop", isFeatured: false),
        Deal(id: UUID(), title: "عطر ادکلن لانکوم La Vie Est Belle", storeId: "khanumi", category: .beauty, oldPrice: 7900000, newPrice: 5490000, code: nil, expiryDays: 6, url: "https://www.khanumi.com/search?q=Lancome%20La%20Vie%20Est%20Belle", imageURL: "https://images.unsplash.com/photo-1541643600914-78b084683601?w=800&q=80&auto=format&fit=crop", isFeatured: false),
        Deal(id: UUID(), title: "گردنبند طلا ۱۸ عیار با آویز قلب", storeId: "digikala", category: .gold, oldPrice: 18500000, newPrice: 14900000, code: nil, expiryDays: 4, url: "https://www.digikala.com/search/?q=%DA%AF%D8%B1%D8%AF%D9%86%D8%A8%D9%86%D8%AF%20%D8%B7%D9%84%D8%A7", imageURL: "https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=800&q=80&auto=format&fit=crop", isFeatured: false),
        Deal(id: UUID(), title: "مایکروویو دوو ۲۸ لیتر", storeId: "daewoo", category: .homeAppliance, oldPrice: 11500000, newPrice: 8900000, code: nil, expiryDays: 3, url: "https://www.daewoo.ir/search?q=%D9%85%D8%A7%DB%8C%DA%A9%D8%B1%D9%88%D9%88%DB%8C%D9%88", imageURL: "https://images.unsplash.com/photo-1574269909862-7e1d499eff42?w=800&q=80&auto=format&fit=crop", isFeatured: false),
        Deal(id: UUID(), title: "قهوه‌ساز نسپرسو مدل Essenza Mini", storeId: "snowa", category: .homeAppliance, oldPrice: 9800000, newPrice: 7200000, code: "SNOWA15", expiryDays: 5, url: "https://www.snowa.ir/search?q=%D9%82%D9%87%D9%88%D9%87%20%D8%B3%D8%A7%D8%B2", imageURL: "https://images.unsplash.com/photo-1511920170033-f8396924c348?w=800&q=80&auto=format&fit=crop", isFeatured: false),
        Deal(id: UUID(), title: "اسپیکر بلوتوثی JBL Flip 6", storeId: "digikala", category: .digital, oldPrice: 6900000, newPrice: 4900000, code: nil, expiryDays: 2, url: "https://www.digikala.com/search/?q=JBL%20Flip%206", imageURL: "https://images.unsplash.com/photo-1608043152269-423dbba4e7e1?w=800&q=80&auto=format&fit=crop", isFeatured: false),
        Deal(id: UUID(), title: "پک ۶ عددی شامپو و نرم‌کننده", storeId: "snappmarket", category: .supermarket, oldPrice: 890000, newPrice: 540000, code: "SNAPP20", expiryDays: 1, url: "https://snapp.market/search?q=%D8%B4%D8%A7%D9%85%D9%BE%D9%88", imageURL: "https://images.unsplash.com/photo-1556228578-8c89e6adf883?w=800&q=80&auto=format&fit=crop", isFeatured: false)
    ]
}
import Foundation

// MARK: - Category
enum DealCategory: String, CaseIterable, Identifiable, Codable {
    case all = "همه"
    case general = "عمومی"
    case digital = "موبایل و دیجیتال"
    case homeAppliance = "لوازم خانگی و برقی"
    case fashion = "پوشاک"
    case supermarket = "سوپرمارکتی"
    case beauty = "آرایشی و بهداشتی"
    case gold = "طلا و زیورآلات"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .all: return "square.grid.2x2.fill"
        case .general: return "tag.fill"
        case .digital: return "iphone"
        case .homeAppliance: return "refrigerator.fill"
        case .fashion: return "tshirt.fill"
        case .supermarket: return "cart.fill"
        case .beauty: return "sparkles"
        case .gold: return "crown.fill"
        }
    }
}

// MARK: - Store
struct Store: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let url: String
    let colorHex: String

    static let all: [Store] = [
        Store(id: "digikala", name: "دیجی‌کالا", url: "https://www.digikala.com", colorHex: "#EF4056"),
        Store(id: "snappmarket", name: "اسنپ‌مارکت", url: "https://snapp.market", colorHex: "#FF00A8"),
        Store(id: "snappshop", name: "اسنپ‌شاپ", url: "https://shop.snapp.ir", colorHex: "#FF6B00"),
        Store(id: "basalam", name: "باسلام", url: "https://basalam.com", colorHex: "#00A693"),
        Store(id: "okala", name: "اکالا", url: "https://okala.com", colorHex: "#00B140"),
        Store(id: "khanumi", name: "خانومی", url: "https://www.khanumi.com", colorHex: "#C2185B"),
        Store(id: "technolife", name: "تکنولایف", url: "https://www.technolife.ir", colorHex: "#2563EB"),
        Store(id: "entekhab", name: "انتخاب سنتر", url: "https://www.entekhabcenter.com", colorHex: "#7C3AED"),
        Store(id: "snowa", name: "اسنوا", url: "https://www.snowa.ir", colorHex: "#0EA5E9"),
        Store(id: "daewoo", name: "دوو", url: "https://www.daewoo.ir", colorHex: "#DC2626")
    ]

    static func name(for id: String) -> String {
        all.first { $0.id == id }?.name ?? id
    }
}

// MARK: - Deal
struct Deal: Identifiable, Hashable, Codable {
    let id: UUID
    let title: String
    let storeId: String
    let category: DealCategory
    let oldPrice: Int
    let newPrice: Int
    let code: String?
    let expiryDays: Int
    let url: String
    let imageURL: String? = nil
    let isFeatured: Bool

    var storeName: String { Store.name(for: storeId) }

    /// The link the card opens: a product search URL, never just a homepage.
    var productURL: URL? { URL(string: url) }
    var productImageURL: URL? { imageURL.flatMap { URL(string: $0) } }

    var discountPercent: Int {
        guard oldPrice > 0, newPrice < oldPrice else { return 0 }
        return Int(round(Double(oldPrice - newPrice) / Double(oldPrice) * 100))
    }

    func priceText(_ price: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale(identifier: "fa_IR")
        return (f.string(from: NSNumber(value: price)) ?? "\(price)") + " تومان"
    }
}

// MARK: - Custom site added by the user ("سایت‌های من")
struct CustomSite: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var url: String

    init(id: UUID = UUID(), name: String, url: String) {
        self.id = id
        self.name = name
        self.url = url
    }

    var displayURL: URL? {
        var s = url.trimmingCharacters(in: .whitespacesAndNewlines)
        if !s.hasPrefix("http://") && !s.hasPrefix("https://") { s = "https://" + s }
        return URL(string: s)
    }
}

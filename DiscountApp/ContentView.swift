import SwiftUI
import UIKit

// MARK: - Helpers
struct GradientBackground: View {
    var body: some View {
        LinearGradient(colors: [Color.purple.opacity(0.35), Color.blue.opacity(0.30), Color.green.opacity(0.25)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
    }
}

func timeUntilMidnight() -> String {
    let cal = Calendar.current
    let now = Date()
    guard let end = cal.date(bySettingHour: 23, minute: 59, second: 59, of: now) else { return "--:--:--" }
    let diff = Int(end.timeIntervalSince(now))
    let h = diff / 3600, m = (diff % 3600) / 60, s = diff % 60
    return String(format: "%02d:%02d:%02d", h, m, s)
}

// MARK: - Product image (photo, or large category icon as fallback)
struct ProductImageView: View {
    let deal: Deal
    var body: some View {
        ZStack {
            LinearGradient(colors: [.purple.opacity(0.55), .blue.opacity(0.55), .green.opacity(0.45)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            if let url = deal.productImageURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        Image(systemName: deal.category.icon).font(.system(size: 64)).foregroundColor(.white.opacity(0.9))
                    case .empty:
                        ProgressView().tint(.white)
                    @unknown default:
                        Image(systemName: deal.category.icon).font(.system(size: 64)).foregroundColor(.white.opacity(0.9))
                    }
                }
            } else {
                Image(systemName: deal.category.icon).font(.system(size: 64)).foregroundColor(.white.opacity(0.9))
            }
            VStack {
                Spacer()
                HStack {
                    Text(deal.storeName).font(.caption.bold()).padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.black.opacity(0.55)).foregroundColor(.white).clipShape(Capsule())
                    Spacer()
                }.padding(8)
            }
        }
        .frame(maxWidth: .infinity).frame(height: 170)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

// MARK: - Deal card
struct DealCardView: View {
    @EnvironmentObject var store: DealStore
    @Environment(\.openURL) private var openURL
    let deal: Deal
    @State private var copied = false

    var body: some View {
        VStack(alignment: .trailing, spacing: 10) {
            ProductImageView(deal: deal)
            HStack {
                Text("\(deal.discountPercent)٪ تخفیف")
                    .font(.caption.bold())
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing))
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                Spacer()
                Text(deal.storeName)
                    .font(.caption)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.15))
                    .clipShape(Capsule())
                Button { store.toggleFavorite(deal) } label: {
                    Image(systemName: store.isFavorite(deal) ? "heart.fill" : "heart")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
            Text(deal.title)
                .font(.headline)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
            HStack(spacing: 8) {
                Text(deal.priceText(deal.newPrice))
                    .font(.headline).foregroundColor(.green)
                Text(deal.priceText(deal.oldPrice))
                    .font(.subheadline)
                    .strikethrough()
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(deal.expiryDays) روز مانده")
                    .font(.caption).foregroundColor(.orange)
            }
            HStack(spacing: 8) {
                if let code = deal.code {
                    Button { UIPasteboard.general.string = code; copied = true } label: {
                        Label(copied ? "کپی شد ✓" : "کد: \(code)", systemImage: "doc.on.doc")
                            .font(.caption.bold())
                    }
                    .buttonStyle(.bordered)
                }
                Spacer()
                if let url = URL(string: deal.url) {
                    Link("مشاهده محصول", destination: url)
                        .font(.subheadline.bold())
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        .contentShape(RoundedRectangle(cornerRadius: 22))
        .onTapGesture {
            if let url = deal.productURL { openURL(url) }
        }
    }
}

// MARK: - Home
struct HomeView: View {
    @EnvironmentObject var store: DealStore
    @State private var countdown = timeUntilMidnight()
    @State private var showAddDeal = false
    @State private var showWatch = false
    @State private var refreshMessage = false
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ZStack { GradientBackground()
                ScrollView {
                    VStack(alignment: .trailing, spacing: 18) {
                        // Header
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("تخفیف‌یاب")
                                .font(.system(size: 34, weight: .black))
                            Text("همه تخفیف‌ها، یه جا — دیگه سایت‌به‌سایت نگرد")
                                .font(.subheadline).foregroundColor(.secondary)
                        }.frame(maxWidth: .infinity, alignment: .trailing)

                        // Search
                        TextField("جستجو: آیفون، یخچال، کفش…", text: $store.searchText)
                            .textFieldStyle(.roundedBorder)
                            .environment(\.layoutDirection, .rightToLeft)

                        // Refresh status
                        HStack(spacing: 8) {
                            if store.isRefreshing {
                                ProgressView().scaleEffect(0.8)
                                Text("در حال به‌روزرسانی…").font(.caption).foregroundColor(.secondary)
                            } else if refreshMessage || store.justRefreshed {
                                Label("به‌روز شد ✓", systemImage: "checkmark.circle.fill")
                                    .font(.caption.bold()).foregroundColor(.green)
                            }
                            Spacer()
                            Text(store.refreshText).font(.caption).foregroundColor(.secondary)
                            Button {
                                Task {
                                    await store.refresh()
                                    refreshMessage = true
                                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                                    refreshMessage = false
                                }
                            } label: {
                                Label("به‌روزرسانی", systemImage: "arrow.clockwise")
                                    .font(.caption.bold())
                            }
                            .buttonStyle(.bordered)
                            .disabled(store.isRefreshing)
                        }

                        // Hero — Deal of the day
                        if let hero = store.dealOfTheDay {
                            VStack(alignment: .trailing, spacing: 10) {
                                HStack {
                                    Text("🔥 تخفیف روز").font(.headline)
                                    Spacer()
                                    Label(countdown, systemImage: "timer")
                                        .font(.caption.bold()).monospacedDigit()
                                        .padding(6).background(Color.black.opacity(0.25)).clipShape(Capsule())
                                }
                                Text(hero.title).font(.title3.bold()).multilineTextAlignment(.trailing)
                                Text("\(hero.discountPercent)٪ تخفیف در \(hero.storeName) — \(hero.priceText(hero.newPrice))")
                                    .font(.subheadline)
                                DealCardView(deal: hero)
                            }
                            .padding(16)
                            .background(LinearGradient(colors: [.purple.opacity(0.85), .blue.opacity(0.85), .green.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 26))
                        }

                        // Categories — circular icons
                        Text("دسته‌بندی").font(.headline).frame(maxWidth: .infinity, alignment: .trailing)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 14) {
                                ForEach(DealCategory.allCases) { cat in
                                    Button { store.selectedCategory = cat } label: {
                                        VStack(spacing: 6) {
                                            Image(systemName: cat.icon)
                                                .font(.title3)
                                                .frame(width: 56, height: 56)
                                                .background(store.selectedCategory == cat ? Color.purple : Color.secondary.opacity(0.18))
                                                .foregroundColor(store.selectedCategory == cat ? .white : .primary)
                                                .clipShape(Circle())
                                            Text(cat.rawValue).font(.caption2).lineLimit(1)
                                        }
                                    }.buttonStyle(.plain)
                                }
                            }
                        }

                        // Filters: store + discount %
                        VStack(spacing: 10) {
                            Picker("فروشگاه", selection: $store.selectedStoreId) {
                                Text("همه فروشگاه‌ها").tag("all")
                                ForEach(Store.all, id: \.id) { s in Text(s.name).tag(s.id) }
                            }.pickerStyle(.menu)
                            Picker("حداقل تخفیف", selection: $store.minDiscount) {
                                Text("همه").tag(0)
                                Text("۲۰٪+").tag(20)
                                Text("۳۰٪+").tag(30)
                                Text("۵۰٪+").tag(50)
                            }.pickerStyle(.segmented)
                            Toggle("فقط علاقه‌مندی‌ها", isOn: $store.showFavoritesOnly)
                                .font(.subheadline)
                        }
                        .padding(12).background(.ultraThinMaterial).clipShape(RoundedRectangle(cornerRadius: 18))

                        // Featured horizontal
                        if !store.featuredDeals.isEmpty {
                            Text("پیشنهادهای ویژه").font(.headline).frame(maxWidth: .infinity, alignment: .trailing)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(store.featuredDeals) { deal in
                                        DealCardView(deal: deal).frame(width: 300)
                                    }
                                }
                            }
                        }

                        // Watched
                        if !store.watchedDeals.isEmpty {
                            Text("دیده‌بان شما").font(.headline).frame(maxWidth: .infinity, alignment: .trailing)
                            ForEach(store.watchedDeals) { deal in DealCardView(deal: deal) }
                        }

                        // All deals
                        Text("همه تخفیف‌ها (\(store.filteredDeals.count))").font(.headline).frame(maxWidth: .infinity, alignment: .trailing)
                        if store.filteredDeals.isEmpty {
                            Text("تخفیفی پیدا نشد. فیلترها را تغییر بدهید.")
                                .foregroundColor(.secondary).padding()
                        }
                        ForEach(store.filteredDeals) { deal in DealCardView(deal: deal) }
                    }
                    .padding()
                }
                .refreshable { await store.refresh() }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showWatch = true } label: { Image(systemName: "bell.badge") }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button { showAddDeal = true } label: { Label("افزودن تخفیف", systemImage: "plus") }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await store.refresh()
                            refreshMessage = true
                            try? await Task.sleep(nanoseconds: 2_000_000_000)
                            refreshMessage = false
                        }
                    } label: {
                        Label("به‌روزرسانی", systemImage: "arrow.clockwise")
                    }
                    .disabled(store.isRefreshing)
                }
            }
            .onReceive(timer) { _ in countdown = timeUntilMidnight() }
            .sheet(isPresented: $showAddDeal) { AddDealView() }
            .sheet(isPresented: $showWatch) { WatchView() }
        }
    }
}

// MARK: - Add deal form
struct AddDealView: View {
    @EnvironmentObject var store: DealStore
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var storeId = "digikala"
    @State private var category: DealCategory = .general
    @State private var oldPrice = ""
    @State private var newPrice = ""
    @State private var code = ""
    @State private var url = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("نام کالا / تخفیف", text: $title)
                Picker("فروشگاه", selection: $storeId) {
                    ForEach(Store.all, id: \.id) { s in Text(s.name).tag(s.id) }
                    ForEach(store.customSites) { s in Text(s.name).tag(s.name) }
                }
                Picker("دسته", selection: $category) {
                    ForEach(DealCategory.allCases.filter { $0 != .all }) { c in Text(c.rawValue).tag(c) }
                }
                TextField("قیمت قبل (تومان)", text: $oldPrice).keyboardType(.numberPad)
                TextField("قیمت بعد (تومان)", text: $newPrice).keyboardType(.numberPad)
                TextField("کد تخفیف (اختیاری)", text: $code)
                TextField("لینک", text: $url).keyboardType(.URL).autocapitalization(.none)
            }
            .navigationTitle("افزودن دستی تخفیف")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("بستن") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("ذخیره") {
                        store.addDeal(title: title, storeId: storeId, category: category,
                                      oldPrice: Int(oldPrice) ?? 0, newPrice: Int(newPrice) ?? 0,
                                      code: code, url: url)
                        dismiss()
                    }.disabled(title.isEmpty)
                }
            }
        }
    }
}

// MARK: - Watch keywords
struct WatchView: View {
    @EnvironmentObject var store: DealStore
    @Environment(\.dismiss) var dismiss
    @State private var word = ""

    var body: some View {
        NavigationStack {
            List {
                Section("کلیدواژه دیده‌بان — مثل آیفون، یخچال") {
                    HStack {
                        TextField("مثلاً آیفون", text: $word)
                        Button("افزودن") { store.addWatchKeyword(word); word = "" }
                    }
                    ForEach(store.watchKeywords, id: \.self) { w in
                        HStack { Text(w); Spacer(); Button { store.removeWatchKeyword(w) } label: { Image(systemName: "trash") } }
                    }
                }
                Section("تخفیف‌های دیده‌بان") {
                    if store.watchedDeals.isEmpty { Text("هنوز موردی نیست.") }
                    ForEach(store.watchedDeals) { deal in Text(deal.title) }
                }
            }
            .navigationTitle("دیده‌بان کلیدواژه")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("بستن") { dismiss() } } }
        }
    }
}

// MARK: - Favorites
struct FavoritesView: View {
    @EnvironmentObject var store: DealStore
    var body: some View {
        NavigationStack {
            ZStack { GradientBackground()
                ScrollView {
                    VStack(spacing: 12) {
                        if store.favoriteIds.isEmpty {
                            Text("هنوز چیزی را به علاقه‌مندی اضافه نکرده‌اید. روی قلب هر تخفیف بزنید.")
                                .foregroundColor(.secondary).padding()
                        }
                        ForEach(store.deals.filter { store.favoriteIds.contains($0.id) }) { deal in
                            DealCardView(deal: deal)
                        }
                    }.padding()
                }
            }.navigationTitle("علاقه‌مندی‌ها")
        }
    }
}

// MARK: - My Sites
struct MySitesView: View {
    @EnvironmentObject var store: DealStore
    @State private var name = ""
    @State private var url = ""

    var body: some View {
        NavigationStack {
            ZStack { GradientBackground()
                List {
                    Section("افزودن سایت جدید") {
                        TextField("نام سایت — مثلاً تکنولایف", text: $name)
                        TextField("آدرس — مثلاً technolife.ir", text: $url)
                            .keyboardType(.URL).autocapitalization(.none)
                        Button("افزودن سایت") {
                            store.addCustomSite(name: name, url: url); name = ""; url = ""
                        }.disabled(name.isEmpty || url.isEmpty)
                        Text("از به‌روزرسانی بعدی، تخفیف‌های این سایت هم جستجو و با نام خودش نمایش داده می‌شود.")
                            .font(.caption).foregroundColor(.secondary)
                    }
                    Section("سایت‌های پیش‌فرض") {
                        ForEach(Store.all, id: \.id) { s in
                            HStack { Text(s.name); Spacer(); Text(s.url).font(.caption).foregroundColor(.secondary) }
                        }
                    }
                    Section("سایت‌های من (\(store.customSites.count))") {
                        if store.customSites.isEmpty { Text("هنوز سایتی اضافه نکرده‌اید.") }
                        ForEach(store.customSites) { site in
                            HStack {
                                VStack(alignment: .trailing) { Text(site.name); Text(site.url).font(.caption).foregroundColor(.secondary) }
                                Spacer()
                                if let u = site.displayURL { Link("باز کردن", destination: u) }
                                Button { store.deleteCustomSite(site) } label: { Image(systemName: "trash").foregroundColor(.red) }
                            }
                        }
                        .onDelete(perform: store.deleteCustomSite)
                    }
                }
                .scrollContentBackground(.hidden)
            }.navigationTitle("سایت‌های من")
        }
    }
}

// MARK: - ContentView (tabs)
struct ContentView: View {
    var body: some View {
        TabView {
            HomeView().tabItem { Label("خانه", systemImage: "house.fill") }
            FavoritesView().tabItem { Label("علاقه‌مندی‌ها", systemImage: "heart.fill") }
            MySitesView().tabItem { Label("سایت‌های من", systemImage: "globe") }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }
}

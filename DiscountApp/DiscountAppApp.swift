import SwiftUI

@main
struct DiscountAppApp: App {
    @StateObject private var store = DealStore()

    init() {
        // Vazirmatn if bundled; otherwise the system font is used.
        // To use Vazirmatn, add Vazirmatn-Regular.ttf / Vazirmatn-Bold.ttf
        // to the target and list them in Info.plist under UIAppFonts.
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environment(\.layoutDirection, .rightToLeft)
                .preferredColorScheme(nil)
        }
    }
}

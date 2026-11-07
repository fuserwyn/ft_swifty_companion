import SwiftUI

@main
struct SwiftyCompanionApp: App {
    @StateObject private var searchModel = SearchViewModel(api: IntraAPIService())

    var body: some Scene {
        WindowGroup {
            SearchView(model: searchModel)
        }
    }
}

enum Theme {
    static let background = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? .systemGroupedBackground
            : UIColor(red: 0xF4 / 255, green: 0xF6 / 255, blue: 0xFF / 255, alpha: 1)
    })
    static let cardRadius: CGFloat = 16
}

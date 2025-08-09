import SwiftUI

@main
struct DiaryPaymentsAppApp: App {
    @StateObject private var appState = AppState()
    private let persistence = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(appState)
                .environment(\.managedObjectContext, persistence.container.viewContext)
        }
    }
}

struct RootTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("ホーム")
                }

            DiaryView()
                .tabItem {
                    Image(systemName: "book.pages.fill")
                    Text("日記")
                }

            PaymentsView()
                .tabItem {
                    Image(systemName: "creditcard.fill")
                    Text("支払い")
                }

            SearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("検索")
                }

            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("設定")
                }
        }
    }
}



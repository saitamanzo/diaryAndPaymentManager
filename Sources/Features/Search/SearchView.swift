import SwiftUI

struct SearchView: View {
    @EnvironmentObject private var appState: AppState
    @State private var query: String = ""

    var body: some View {
        NavigationView {
            List(filteredResults) { entry in
                VStack(alignment: .leading) {
                    Text(entry.title).font(.headline)
                    Text(entry.text).lineLimit(1).foregroundColor(.secondary)
                }
            }
                .font(.footnote)
            .searchable(text: $query)
            .navigationTitle("検索")
        }
    }

    private var filteredResults: [DiaryEntry] {
        guard !query.isEmpty else { return appState.diaryEntries }
        return appState.diaryEntries.filter { e in
            e.title.localizedCaseInsensitiveContains(query) ||
            e.text.localizedCaseInsensitiveContains(query)
        }
    }
}



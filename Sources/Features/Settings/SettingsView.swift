import SwiftUI

struct SettingsView: View {
    @AppStorage("isAppLockEnabled") private var isAppLockEnabled: Bool = false
    @AppStorage("useDarkMode") private var useDarkMode: Bool = false
    @AppStorage("monthlyBudget") private var monthlyBudget: Int = 0

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("セキュリティ")) {
                    Toggle("アプリロック（擬似）", isOn: $isAppLockEnabled)
                }
                Section(header: Text("表示")) {
                    Toggle("ダークモード（擬似）", isOn: $useDarkMode)
                }
                Section(header: Text("予算")) {
                    Stepper(value: $monthlyBudget, in: 0...1_000_000, step: 1000) {
                        Text("月次予算: \(monthlyBudget) 円")
                    }
                }
                Section(header: Text("データ")) {
                    Button("エクスポート（将来対応）") {}
                }
                Section(header: Text("情報")) {
                    HStack {
                        Text("バージョン")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-")
                            .foregroundColor(.secondary)
                    }
                }
            }
                .font(.footnote)
            .navigationTitle("設定")
        }
    }
}



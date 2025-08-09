import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Diary.date, ascending: false)],
        animation: .default
    ) private var diaries: FetchedResults<Diary>
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Payment.date, ascending: false)],
        animation: .default
    ) private var payments: FetchedResults<Payment>
    @State private var quickTitle: String = ""
    @State private var quickText: String = ""
    @State private var quickRating: Int = 3

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    GroupBox(label: Label("今日の日記クイック作成", systemImage: "square.and.pencil")) {
                        VStack(alignment: .leading, spacing: 12) {
                            TextField("タイトル", text: $quickTitle)
                                .textFieldStyle(.roundedBorder)
                            TextEditor(text: $quickText)
                                .frame(minHeight: 100)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.secondary))
                            HStack {
                                Text("評価")
                                Spacer()
                                RatingView(rating: $quickRating)
                            }
                            Button(action: addQuickDiary) {
                                Label("保存", systemImage: "tray.and.arrow.down.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(8)
                    }

                    GroupBox(label: Label("最近の記録", systemImage: "clock.fill")) {
                        VStack(alignment: .leading, spacing: 8) {
                            if diaries.isEmpty {
                                Text("まだ記録がありません")
                                    .foregroundColor(.secondary)
                            } else {
                                ForEach(Array(diaries.prefix(5))) { entry in
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(entry.title)
                                                .font(.headline)
                                            Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        RatingView(rating: .constant(Int(entry.rating)))
                                            .allowsHitTesting(false)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                        .padding(8)
                    }

                    GroupBox(label: Label("支出サマリー", systemImage: "yensign.circle.fill")) {
                        VStack(alignment: .leading, spacing: 8) {
                            let monthTotal = monthTotalAmount()
                            Text("今月: \(format(currency: monthTotal))")
                                .font(.headline)
                                .accessibilityLabel("今月の支出合計")
                            let budget = UserDefaults.standard.integer(forKey: "monthlyBudget")
                            if budget > 0 {
                                let progress = min(1.0, (monthTotal as NSDecimalNumber).doubleValue / Double(budget))
                                ProgressView(value: progress) {
                                    Text("予算: \(budget) 円")
                                }
                                .tint(progress < 0.8 ? .green : (progress < 1.0 ? .orange : .red))
                            }
                        }
                        .padding(8)
                    }
                }
                    .padding()
                    .font(.footnote)
            }
            .navigationTitle("ホーム")
        }
        .navigationViewStyle(.stack)
    }

    private func addQuickDiary() {
        guard !quickTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                !quickText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let entry = Diary(context: context)
        entry.id = UUID()
        entry.date = Date()
        entry.title = quickTitle.isEmpty ? "今日の記録" : quickTitle
        entry.text = quickText
        entry.rating = Int16(quickRating)
        // Transformable の空配列保存で失敗するエッジケースを避けるため未設定にする
        entry.tags = nil
        entry.placeName = nil
        do {
            try context.save()
        } catch {
            assertionFailure("Quick diary save error: \(error)")
        }
        quickTitle = ""
        quickText = ""
        quickRating = 3
    }

    private func monthTotalAmount() -> Decimal {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: Date())
        guard let start = cal.date(from: comps) else { return Decimal(0) }
        let end = cal.date(byAdding: .month, value: 1, to: start) ?? Date()
        let filtered = payments.filter { $0.date >= start && $0.date < end }
        return filtered.reduce(Decimal(0)) { $0 + ($1.amount as Decimal) }
    }

    private func format(currency amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "JPY"
        return formatter.string(from: amount as NSDecimalNumber) ?? "¥0"
    }
}



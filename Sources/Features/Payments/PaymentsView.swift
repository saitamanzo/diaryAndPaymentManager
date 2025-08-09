import SwiftUI
import CoreData

struct PaymentDetailView: View {
    let entry: Payment
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "creditcard.fill")
                    .foregroundColor(.accentColor)
                Text(format(currency: entry.amount as Decimal))
                    .font(.title2).bold()
            }
            Divider()
            HStack {
                Label(entry.date.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                    .foregroundColor(.secondary)
                Spacer()
                Label(entry.category, systemImage: "tag")
                    .foregroundColor(.secondary)
            }
            if let note = entry.note, !note.isEmpty {
                HStack(alignment: .top) {
                    Image(systemName: "note.text")
                        .foregroundColor(.secondary)
                    Text(note)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color(.systemGray4), radius: 4, x: 0, y: 2)
        .navigationTitle("支払い詳細")
    }
    private func format(currency amount: Decimal) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "JPY"
        return f.string(from: amount as NSDecimalNumber) ?? "¥0"
    }
}

struct PaymentsView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Payment.date, ascending: false)],
        animation: .default
    ) private var payments: FetchedResults<Payment>
    @State private var showingAdd = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ListSectionView
                Button(action: { showingAdd = true }) {
                    Label("支出を追加", systemImage: "plus.circle.fill")
                        .font(.title3)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.bottom, 8)
            }
            .background(Color(.systemGroupedBackground))
            .sheet(isPresented: $showingAdd) {
                PaymentEditViewCoreData()
            }
            .navigationTitle("支払い履歴")
        }
    }

    private var ListSectionView: some View {
        List {
            EditButton()
            Section(header:
                HStack {
                    Image(systemName: "sum")
                        .foregroundColor(.accentColor)
                    Text("今月の合計")
                        .font(.headline)
                }
            ) {
                Text(totalThisMonth())
                    .font(.title3)
                    .bold()
                    .foregroundColor(.accentColor)
            }
            ForEach(groupedByDateKeys, id: \.self) { keyDate in
                Section(header:
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.accentColor)
                        Text(sectionTitle(for: keyDate))
                            .font(.headline)
                    }
                ) {
                    ForEach(entriesByDate[keyDate] ?? []) { record in
                        NavigationLink(destination: PaymentDetailView(entry: record)) {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Image(systemName: "creditcard")
                                        .foregroundColor(.accentColor)
                                    Text(format(currency: record.amount as Decimal))
                                        .font(.headline)
                                    Spacer()
                                    Text(record.date.formatted(date: .abbreviated, time: .omitted))
                                        .foregroundColor(.secondary)
                                }
                                HStack(spacing: 12) {
                                    Label(record.category, systemImage: "tag")
                                        .foregroundColor(.secondary)
                                    if let note = record.note, !note.isEmpty {
                                        Label(record.note ?? "", systemImage: "note.text")
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                            }
                            .padding(10)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color(.systemGray5), radius: 2, x: 0, y: 1)
                        }
                    }
                    .onDelete { offsets in
                        deleteEntries(at: offsets, in: keyDate)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
        private var entriesByDate: [Date: [Payment]] {
            Dictionary(grouping: Array(payments)) { entry in
                Calendar.current.startOfDay(for: entry.date)
            }
        }
        private var groupedByDateKeys: [Date] {
            entriesByDate.keys.sorted(by: >)
        }
        private func sectionTitle(for date: Date) -> String {
            date.formatted(date: .abbreviated, time: .omitted)
        }

        private func deleteEntries(at offsets: IndexSet, in dateKey: Date) {
            guard let list = entriesByDate[dateKey] else { return }
            let targets = offsets.map { list[$0] }
            targets.forEach { context.delete($0) }
            try? context.save()
        }

        private func totalThisMonth() -> String {
            let cal = Calendar.current
            let comps = cal.dateComponents([.year, .month], from: Date())
            guard let start = cal.date(from: comps) else { return format(currency: Decimal(0)) }
            let end = cal.date(byAdding: .month, value: 1, to: start) ?? Date()
            let filtered = payments.filter { $0.date >= start && $0.date < end }
            let total = filtered.reduce(Decimal(0)) { $0 + (($1.amount as Decimal)) }
            return format(currency: total)
        }

        private func format(currency amount: Decimal) -> String {
            let f = NumberFormatter()
            f.numberStyle = .currency
            f.currencyCode = "JPY"
            return f.string(from: amount as NSDecimalNumber) ?? "¥0"
        }
    }
// ここでstruct PaymentsViewの定義終了

struct PaymentEditViewCoreData: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context
    @State private var amountText: String = ""
    @State private var selectedCategory: String = "食費"
    @State private var customCategory: String = ""
    @State private var note: String = ""
    private let categories = ["食費", "交通費", "娯楽", "日用品", "その他"]

    // PaymentDetailViewはファイル冒頭で定義済み
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("金額")) {
                    TextField("¥0", text: $amountText)
                        .keyboardType(.decimalPad)
                }
                Section(header: Text("カテゴリー")) {
                    Picker("カテゴリー", selection: $selectedCategory) {
                        ForEach(categories, id: \ .self) { cat in
                            Text(cat)
                        }
                    }
                    .pickerStyle(.menu)
                    if selectedCategory == "その他" {
                        TextField("カテゴリー名を入力", text: $customCategory)
                    }
                }
                Section(header: Text("メモ")) {
                    TextField("任意", text: $note)
                }
            }
            .navigationTitle("支出を追加")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }.disabled(decimalAmount() == nil)
                }
            }
        }
    }

    private func decimalAmount() -> Decimal? {
        let filtered = amountText.replacingOccurrences(of: ",", with: "").replacingOccurrences(of: "¥", with: "")
        return Decimal(string: filtered)
    }

    private func save() {
        guard let amount = decimalAmount() else { return }
        let p = Payment(context: context)
        p.id = UUID()
        p.date = Date()
        p.amount = amount as NSDecimalNumber
        if selectedCategory == "その他" {
            p.category = customCategory.isEmpty ? "その他" : customCategory
        } else {
            p.category = selectedCategory
        }
        p.note = note
        try? context.save()
        dismiss()
    }
}



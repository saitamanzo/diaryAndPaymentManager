import SwiftUI
// PhotosUIはiOS16+のため、iOS15互換として自前のImagePicker(UIKit)を使用
import CoreData

struct DiaryView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Diary.date, ascending: false)],
        animation: .default
    ) private var diaries: FetchedResults<Diary>
    @State private var showingAdd = false

    var body: some View {
        NavigationView {
            List {
                ForEach(groupedByDateKeys, id: \.self) { keyDate in
                    Section(header: Text(sectionTitle(for: keyDate))) {
                        ForEach(entriesByDate[keyDate] ?? []) { entry in
                            NavigationLink(destination: DiaryDetailView(entry: entry)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.title).font(.headline)
                                    Text(entry.text ?? "").lineLimit(2).foregroundColor(.secondary)
                                }
                            }
                        }
                        .onDelete { indexSet in
                            deleteEntries(at: indexSet, in: keyDate)
                        }
                    }
                }
            }
                .font(.footnote)
            .navigationTitle("日記")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAdd = true }) {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("新規作成")
                }
                    ToolbarItem(placement: .navigationBarLeading) {
                        EditButton()
                    }
            }
            .sheet(isPresented: $showingAdd) {
                DiaryEditViewCoreData()
                    .imagePickerSheet
            }
        }
    }

    private var entriesByDate: [Date: [Diary]] {
        Dictionary(grouping: Array(diaries)) { entry in
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
}

struct DiaryDetailView: View {
    let entry: Diary
    @State private var loadedImage: UIImage? = nil
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(entry.title).font(.title2).bold()
                HStack {
                    Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                        .foregroundColor(.secondary)
                    Spacer()
                    RatingView(rating: .constant(Int(entry.rating)))
                }
                if let path = entry.imagePath, let image = ImageStore.load(path: path) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(8)
                }
                Text(entry.text ?? "")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
        }
        .navigationTitle("詳細")
    }
}

struct DiaryEditViewCoreData: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context
    @State private var title: String = ""
    @State private var text: String = ""
    @State private var rating: Int = 3
    @State private var pickedImage: UIImage? = nil
    @State private var showImagePicker = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本情報")) {
                    TextField("タイトル", text: $title)
                    TextEditor(text: $text).frame(minHeight: 120)
                    HStack {
                        Text("評価")
                        Spacer()
                        RatingView(rating: $rating)
                    }
                }
                Section(header: Text("写真")) {
                    if let image = pickedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(8)
                    }
                    Button {
                        showImagePicker = true
                    } label: {
                        Label("写真を選択", systemImage: "photo.on.rectangle")
                    }
                }
            }
            .navigationTitle("新規日記")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }.disabled(title.isEmpty && text.isEmpty)
                }
            }
        }
    }

    private func save() {
        let obj = Diary(context: context)
        obj.id = UUID()
        obj.date = Date()
        obj.title = title.isEmpty ? "無題" : title
        obj.text = text
        obj.rating = Int16(rating)
        // Transformable 空配列の保存で失敗する環境があるため未設定にする
        obj.tags = nil
        obj.placeName = nil
        if let image = pickedImage, let path = try? ImageStore.save(image: image) {
            obj.imagePath = path
        }
        do {
            try context.save()
        } catch {
            assertionFailure("Diary save error: \(error)")
            return
        }
        dismiss()
    }
}

extension DiaryEditViewCoreData {
    @ViewBuilder
    var imagePickerSheet: some View {
        EmptyView()
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $pickedImage)
            }
    }
}




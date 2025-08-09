import Foundation
import SwiftUI

final class AppState: ObservableObject {
    @Published var diaryEntries: [DiaryEntry] = []
    @Published var paymentRecords: [PaymentRecord] = []
    @Published var selectedDate: Date = Date()
}

struct DiaryEntry: Identifiable, Hashable {
    let id: UUID
    var date: Date
    var title: String
    var text: String
    var rating: Int
    var tags: [String]
    var placeName: String?
}

struct PaymentRecord: Identifiable, Hashable {
    let id: UUID
    var date: Date
    var amount: Decimal
    var category: String
    var note: String
}



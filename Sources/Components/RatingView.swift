import SwiftUI

struct RatingView: View {
    @Binding var rating: Int
    var max: Int = 5

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...max, id: \.self) { value in
                Image(systemName: value <= rating ? "star.fill" : "star")
                    .foregroundColor(.yellow)
                    .onTapGesture { rating = value }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("評価")
        .accessibilityValue("\(rating) / \(max)")
    }
}



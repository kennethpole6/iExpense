//
//  LabeledField.swift
//  iExpense
//
//  Created by kenneth pole on 2/8/26.
//
import SwiftUI

struct LabeledField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)

            TextField(placeholder, text: $text)
                .padding(14)
                .background(Color(.secondarySystemBackground))
                .clipShape(Capsule())
                .keyboardType(keyboard)
        }
    }
}

#Preview {
    LabeledField(title: "Title", placeholder: "Placeholder", text: .init(get: { "" }, set: { _ in }))
}

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
                .foregroundStyle(.secondary)

            TextField(placeholder, text: $text)
                .padding(12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .keyboardType(keyboard)
        }
    }
}

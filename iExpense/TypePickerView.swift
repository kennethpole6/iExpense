//
//  TypePickerView.swift
//  iExpense
//
//  Created by kenneth pole on 2/8/26.
//

import SwiftUI

struct TypePickerView: View {
    @Binding var selectedType: ExpenseType
    @Binding var customTypeLabel: String

    var body: some View {
        List {
            Section("Common Types") {
                ForEach(ExpenseType.allCases.filter { $0 != .other }) { type in
                    Button {
                        selectedType = type
                    } label: {
                        HStack {
                            Image(systemName: type.icon)
                            Text(type.displayName)
                            Spacer()
                            if selectedType == type {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            Section("Custom") {
                VStack(alignment: .leading, spacing: 12) {
                    TextField("Custom type", text: $customTypeLabel)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    Button("Use Custom Type") {
                        selectedType = .other
                    }
                    .disabled(
                        customTypeLabel.trimmingCharacters(in: .whitespaces)
                            .isEmpty
                    )
                }
            }
        }
        .navigationTitle("Select Type")
    }
}


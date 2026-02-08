//
//  AddExpenseView.swift
//  iExpense
//
//  Created by kenneth pole on 2/8/26.
//

import SwiftUI

struct SecondView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var amount = ""
    @State private var selectedType: ExpenseType = .bills
    @State private var customTypeLabel = ""
    @State private var selectedIcon: String?

    let onAdd: (ExpenseItem) -> Void

    private let icons = [
        "doc.text", "bolt.fill", "wifi", "cart.fill",
        "car.fill", "gamecontroller.fill",
        "fork.knife", "creditcard.fill", "tag",
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                header
                amountField
                descriptionField
                typePicker
                iconPicker
                addButton
                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel", systemImage: "xmark") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Subviews

    private var header: some View {
        VStack(alignment: .center, spacing: 4) {
            Text("Add new expense")
                .font(.title)
                .fontWeight(.semibold)

            Text("Track your spending by adding an expense.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var amountField: some View {
        LabeledField(
            title: "Amount",
            placeholder: "0.00",
            text: $amount,
            keyboard: .decimalPad
        )
    }

    private var descriptionField: some View {
        LabeledField(
            title: "Description",
            placeholder: "e.g. Coffee",
            text: $name
        )
    }

    private var typePicker: some View {
        NavigationLink {
            TypePickerView(
                selectedType: $selectedType,
                customTypeLabel: $customTypeLabel
            )
        } label: {
            HStack {
                Image(systemName: selectedIcon ?? selectedType.icon)
                Text(typeLabel)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.primary)
            }
            .padding(12)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private var typeLabel: String {
        selectedType == .other && !customTypeLabel.isEmpty
            ? customTypeLabel
            : selectedType.displayName
    }

    private var iconPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(icons, id: \.self) { symbol in
                    Button {
                        selectedIcon = symbol
                    } label: {
                        Image(systemName: symbol)
                            .frame(width: 36, height: 36)
                            .foregroundStyle(
                                selectedIcon == symbol ? .white : .primary
                            )
                            .background(
                                Circle().fill(
                                    selectedIcon == symbol
                                        ? Color.accentColor
                                        : Color(.systemGray6)
                                )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var addButton: some View {
        Button("Add Expense") {
            save()
        }
        .disabled(!canSave)
        .frame(maxWidth: .infinity)
        .padding()
        .background(.black)
        .foregroundStyle(.white)
        .cornerRadius(10)
    }

    private var canSave: Bool {
        !name.isEmpty && Double(amount) != nil
    }

    private func save() {
        guard let value = Double(amount) else { return }
        let item = ExpenseItem(
            name: name,
            type: selectedType,
            customTypeLabel: selectedType == .other ? customTypeLabel : nil,
            amount: value,
            icon: selectedIcon
        )
        onAdd(item)
        dismiss()
    }
}

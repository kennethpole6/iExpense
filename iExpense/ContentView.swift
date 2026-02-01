import SwiftUI
import Observation

// MARK: - Expense Type
enum ExpenseType: String, CaseIterable, Identifiable, Codable {
    case bills, electricity, internet, groceries, transport
    case entertainment, dining, subscriptions, other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .bills: return "Bills"
        case .electricity: return "Electricity"
        case .internet: return "Internet"
        case .groceries: return "Groceries"
        case .transport: return "Transport"
        case .entertainment: return "Entertainment"
        case .dining: return "Dining"
        case .subscriptions: return "Subscriptions"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .bills: return "doc.text"
        case .electricity: return "bolt.fill"
        case .internet: return "wifi"
        case .groceries: return "cart.fill"
        case .transport: return "car.fill"
        case .entertainment: return "gamecontroller.fill"
        case .dining: return "fork.knife"
        case .subscriptions: return "creditcard.fill"
        case .other: return "tag"
        }
    }
}

// MARK: - Models
struct ExpenseItem: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let type: ExpenseType
    let customTypeLabel: String?
    let amount: Double
    let icon: String

    init(
        id: UUID = UUID(),
        name: String,
        type: ExpenseType,
        customTypeLabel: String? = nil,
        amount: Double,
        icon: String? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.customTypeLabel = customTypeLabel
        self.amount = amount
        self.icon = icon ?? type.icon
    }

    var displayType: String {
        if type == .other, let label = customTypeLabel, !label.isEmpty {
            return label
        }
        return type.displayName
    }
}

@Observable
final class Expenses {
    var items: [ExpenseItem] = []
}

// MARK: - Reusable Field
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

// MARK: - Type Picker
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
                    .buttonStyle(.borderedProminent)
                    .disabled(customTypeLabel.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .navigationTitle("Select Type")
    }
}

// MARK: - Add Expense View
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
        "fork.knife", "creditcard.fill", "tag"
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
                    Button("Cancel", role: .destructive) {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Subviews

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
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
                    .foregroundStyle(.secondary)
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
                            .foregroundStyle(selectedIcon == symbol ? .white : .primary)
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

// MARK: - Main View
struct ContentView: View {
    @State private var showSheet = false
    @State private var expenses = Expenses()
    @AppStorage("expenses") private var storedData: Data = Data()
    
    var total: Double {
        expenses.items.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(expenses.items) { item in
                    HStack {
                        Image(systemName: item.icon)
                        VStack(alignment: .leading) {
                            Text(item.name)
                            Text(item.displayType)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(item.amount.formatted(.currency(code: "PHP")))
                            .fontWeight(.semibold)
                    }
                }
                .onDelete(perform: delete)
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text("iExpense")
                            .font(.headline)
                        Text(total.formatted(.currency(code: "PHP")))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                  
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add", systemImage: "plus") {
                        showSheet = true
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
            }
            .onAppear(perform: load)
            .onChange(of: expenses.items) { save() }
        }
        .sheet(isPresented: $showSheet) {
            SecondView { expenses.items.append($0) }
        }
    }

    private func delete(at offsets: IndexSet) {
        expenses.items.remove(atOffsets: offsets)
    }

    private func load() {
        guard !storedData.isEmpty else { return }
        expenses.items = (try? JSONDecoder().decode([ExpenseItem].self, from: storedData)) ?? []
    }

    private func save() {
        storedData = (try? JSONEncoder().encode(expenses.items)) ?? Data()
    }
}

#Preview {
    ContentView()
}

import Observation
import SwiftUI

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
    let reminderDate: Date?
    let icon: String

    init(
        id: UUID = UUID(),
        name: String,
        type: ExpenseType,
        customTypeLabel: String? = nil,
        amount: Double,
        reminderDate: Date? = nil,
        icon: String? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.customTypeLabel = customTypeLabel
        self.amount = amount
        self.reminderDate = reminderDate
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

// MARK: - Main View
struct ContentView: View {
    @State private var showSheet = false
    @State private var expenses = Expenses()
    @AppStorage("expenses") private var storedData: Data = Data()

    var total: Double {
        expenses.items.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        TabView {
            // Expenses Tab
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
                .navigationTitle("Expenses").toolbar {
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
            .tabItem {
                Image(systemName: "square.3.stack.3d.middle.fill")
                Text("Expenses")
            }

            // Budget Tab
            BudgetView()
                .tabItem {
                    Image(systemName: "chart.bar.horizontal.page.fill")
                    Text("Budget")
                }
        }
    }

    private func delete(at offsets: IndexSet) {
        expenses.items.remove(atOffsets: offsets)
    }

    private func load() {
        guard !storedData.isEmpty else { return }
        expenses.items =
            (try? JSONDecoder().decode([ExpenseItem].self, from: storedData))
            ?? []
    }

    private func save() {
        storedData = (try? JSONEncoder().encode(expenses.items)) ?? Data()
    }
}

#Preview {
    ContentView()
}

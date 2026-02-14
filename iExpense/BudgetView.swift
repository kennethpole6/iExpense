//
//  BudgetView.swift
//  iExpense
//
//  Created by kenneth pole on 2/8/26.
//

import SwiftUI

struct BudgetCategory: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var spent: Double
    var limit: Double
    var icon: String

    var progress: Double {
        guard limit > 0 else { return 0 }
        return min(spent / limit, 1.0)
    }
    var isOver: Bool { spent > limit }
}

struct BudgetView: View {
    @AppStorage("expenses") private var storedData: Data = Data()
    @Environment(\.colorScheme) private var colorScheme

    @State private var expenses = Expenses()

    @AppStorage("totalBudget") private var totalBudget: Double = 0
    @State private var totalSpent: Double = 0
    @State private var categories: [BudgetCategory] = []
    @State private var showingBudgetSheet = false
    @State private var inputBudget: Double = 0

    private var currencyFormat: FloatingPointFormatStyle<Double>.Currency {
        .currency(code: Locale.current.currency?.identifier ?? "USD")
    }

    private func currencyString(_ value: Double) -> String {
        value.formatted(currencyFormat)
    }

    private var remaining: Double { max(totalBudget - totalSpent, 0) }

    private var monthRange: Range<Int> {
        let calendar = Calendar.current
        let now = Date()
        let days = calendar.range(of: .day, in: .month, for: now) ?? 1..<2
        return days
    }

    private var todayDayOfMonth: Int {
        Calendar.current.component(.day, from: Date())
    }

    private var daysLeftInMonth: Int {
        max(monthRange.upperBound - todayDayOfMonth, 0)
    }

    private var overallProgress: Double {
        guard totalBudget > 0 else { return 0 }
        return min(totalSpent / totalBudget, 1.0)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    budgetOverviewCard
                    categoryBreakdownSection
                }
                .padding()
            }
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Budget")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add Budget", systemImage: "plus") {
                        inputBudget = max(totalBudget, 0)
                        showingBudgetSheet = true
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(
                        "Recalculate",
                        systemImage: "arrow.2.circlepath.circle"
                    ) { recalcFromExpenses() }
                }
            }
            .sheet(isPresented: $showingBudgetSheet) {
                NavigationStack {
                    Form {
                        Section("Total Monthly Budget") {
                            TextField(
                                "Amount",
                                value: $inputBudget,
                                format: .currency(
                                    code: Locale.current.currency?.identifier
                                        ?? "PHP"
                                )
                            )
                            .keyboardType(.decimalPad)
                        }
                    }
                    .navigationTitle("Set Budget")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showingBudgetSheet = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                totalBudget = max(0, inputBudget)
                                recalcFromExpenses()
                                showingBudgetSheet = false
                                inputBudget = 0
                            }
                            .disabled(inputBudget < 0)
                        }
                    }
                }
            }
            .onAppear {
                load()
                recalcFromExpenses()
            }
        }
    }

    private func load() {
        guard !storedData.isEmpty else { return }
        expenses.items =
            (try? JSONDecoder().decode([ExpenseItem].self, from: storedData))
            ?? []
    }
}

// MARK: - Subviews
extension BudgetView {
    fileprivate var budgetOverviewCard: some View {
        VStack(spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Budget")
                        .font(.footnote)
                        .foregroundStyle(.primary)
                    Text(currencyString(totalBudget))
                        .font(.title2).fontWeight(.semibold)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Remaining")
                        .font(.footnote)
                        .foregroundStyle(.primary)
                    Text(currencyString(remaining))
                        .font(.title3).fontWeight(.semibold)
                        .foregroundStyle(remaining > 0 ? .primary : Color.red)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                ProgressView(value: overallProgress) {
                    Text("Spending Progress")
                        .font(.footnote)
                        .foregroundStyle(.primary)
                }
                .tint(overallProgress < 1.0 ? .blue : .red)

                HStack {
                    Text(currencyString(totalSpent))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("of ")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(currencyString(totalBudget))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack {
                Label("Days left: \(daysLeftInMonth)", systemImage: "calendar")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
                if overallProgress >= 1.0 {
                    Label(
                        "Over budget",
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .font(.footnote)
                    .foregroundStyle(.red)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(colorScheme == .dark ? .systemGray5 : .white))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.quaternary, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Budget overview. Total budget \(totalBudget, format: .number). Spent \(totalSpent, format: .number). Remaining \(remaining, format: .number). \(daysLeftInMonth) days left in month."
        )
    }

    fileprivate var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category Breakdown")
                .font(.headline)

            if expenses.items.isEmpty {
                VStack(alignment: .center, spacing: 12) {
                    EmptyStateView()
                }
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            Color(colorScheme == .dark ? .systemGray5 : .white)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(.quaternary, lineWidth: 1)
                )
            } else if categories.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("No categories to show yet")
                        .font(.subheadline).fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                    Text("Tap Recalculate to refresh your category breakdown.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            Color(colorScheme == .dark ? .systemGray5 : .white)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(.quaternary, lineWidth: 1)
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(categories) { category in
                        categoryCard(category)
                    }
                }
            }
        }
    }

    fileprivate func categoryCard(_ category: BudgetCategory) -> some View {
        Button {
            // No action for now
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(
                        category.isOver
                            ? Color.red.opacity(0.15)
                            : Color.primary.opacity(0.15)
                    )
                    Image(systemName: category.icon)
                        .foregroundStyle(category.isOver ? .red : .primary)
                }
                .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(category.name)
                            .font(.subheadline).fontWeight(.semibold)
                        Spacer()
                        Text(currencyString(category.spent))
                            .font(.subheadline)
                    }

                    ProgressView(value: category.progress) {
                        EmptyView()
                    }
                    .tint(category.isOver ? .red : .primary)

                    HStack {
                        Text("Limit: " + currencyString(category.limit))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        if category.isOver {
                            Label(
                                "Over by "
                                    + currencyString(
                                        category.spent - category.limit
                                    ),
                                systemImage: "exclamationmark.triangle.fill"
                            )
                            .font(.caption)
                            .foregroundStyle(.red)
                        } else {
                            Text(
                                "Remaining: "
                                    + currencyString(
                                        max(category.limit - category.spent, 0)
                                    )
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(colorScheme == .dark ? .systemGray5 : .white))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(.quaternary, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(category.name) spent \(category.spent, format: .number) of limit \(category.limit, format: .number)."
        )
    }
}

// MARK: - Helpers
extension BudgetView {
    fileprivate func recalcFromExpenses() {
        // Sum total spent
        totalSpent = expenses.items.reduce(0) { $0 + $1.amount }

        // Build category sums
        var sums: [String: Double] = [:]
        for item in expenses.items {
            let key: String
            if let mirrorType = Mirror(reflecting: item).children.first(where: {
                $0.label == "type"
            })?.value as? String {
                key = mirrorType
            } else {
                key =
                    Mirror(reflecting: item).children.first(where: {
                        $0.label == "name"
                    })?.value as? String ?? "Other"
            }
            sums[key, default: 0] += item.amount
        }

        // Simple icon mapping
        func icon(for name: String) -> String {
            switch name.lowercased() {
            case "bills": return "doc.text"
            case "electricity": return "bolt.fill"
            case "internet": return "wifi"
            case "groceries": return "cart.fill"
            case "transport", "transportation": return "car.fill"
            case "entertainment": return "gamecontroller.fill"
            case "dining", "food": return "fork.knife"
            case "subscriptions", "subscription": return "creditcard.fill"
            case "other": return "tag"
            default: return "tag"
            }
        }

        // Determine per-category limits (fallback simple split if totalBudget available)
        let total = totalBudget
        let defaultLimitPerCategory: Double =
            (total > 0 && !sums.isEmpty) ? total / Double(sums.count) : 0

        categories = sums.map { (name, spent) in
            BudgetCategory(
                name: name,
                spent: spent,
                limit: defaultLimitPerCategory,
                icon: icon(for: name)
            )
        }.sorted { $0.name < $1.name }
    }

    fileprivate func recalcTotals() {
        totalSpent = categories.reduce(0) { $0 + $1.spent }
    }
}

#Preview {
    NavigationStack { BudgetView() }
}

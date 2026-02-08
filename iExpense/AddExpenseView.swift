//
//  AddExpenseView.swift
//  iExpense
//
//  Created by kenneth pole on 2/8/26.
//

import SwiftUI
import UserNotifications

struct SecondView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var amount = ""
    @State private var selectedType: ExpenseType = .bills
    @State private var customTypeLabel = ""
    @State private var selectedIcon: String?
    @State private var enableReminder = false
    @State private var reminderDate = Date().addingTimeInterval(3600)

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
                reminderSection
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

    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $enableReminder) {
                Label("Remind me", systemImage: "bell")
            }
            .tint(.accentColor)
            Text("Set a reminder to be notified when this expense is due.").font(.system(size: 12)).foregroundStyle(Color(.secondaryLabel))

            if enableReminder {
                DatePicker(
                    "Reminder time",
                    selection: $reminderDate,
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.compact)
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
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
            reminderDate: enableReminder ? reminderDate : nil,
            icon: selectedIcon
        )
        onAdd(item)
        scheduleReminderIfNeeded(for: item)
        dismiss()
    }
    
    private func scheduleReminderIfNeeded(for item: ExpenseItem) {
        guard let date = item.reminderDate, date > Date() else { return }

        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                scheduleNotification(item: item, at: date)
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    if granted {
                        scheduleNotification(item: item, at: date)
                    }
                }
            default:
                break
            }
        }
    }

    private func scheduleNotification(item: ExpenseItem, at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Upcoming Expense"
        content.body = "You have an upcoiming expense \(item.name) amounting of \(item.amount.formatted(.currency(code: Locale.current.currency?.identifier ?? "PHP")))"
        content.sound = .default

        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        let request = UNNotificationRequest(identifier: item.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}

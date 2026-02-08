//
//  BudgetView.swift
//  iExpense
//
//  Created by kenneth pole on 2/8/26.
//

import SwiftUI

struct BudgetView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "chart.pie")
                    .font(.system(size: 48))
                    .foregroundStyle(.primary)
                Text("Budget")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Set and track your budget here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("Budget")
        }
    }
}

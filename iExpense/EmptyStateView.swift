//
//  EmptyStateView.swift
//  iExpense
//
//  Created by kenneth pole on 2/14/26.
//

import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 50))
                .foregroundStyle(.gray)

            Text("No Data")
                .font(.title2)
                .bold()    
            Text("Add some expenses to see your breakdown here.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
        }
        .multilineTextAlignment(.center)
        .padding()
    }
}

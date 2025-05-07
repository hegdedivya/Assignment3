//
//  ActivitiesDetailView.swift
//  Assignment3
//
//  Created by 安雨馨 on 2025/5/7.
//
import SwiftUI
import Foundation

struct ActivityDetailView: View {
    var activity: Activity

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Activity: \(activity.name)")
                .font(.title2)
            Text("Date: \(activity.date.formatted(date: .long, time: .omitted))")

            Divider()

            Text("Members")
                .font(.headline)
            ForEach(activity.members, id: \.self) { member in
                Text(member)
            }

            Divider()

            Text("Expenses")
                .font(.headline)
            ForEach(activity.expenses) { expense in
                HStack {
                    Text(expense.itemName)
                    Spacer()
                    Text("$\(expense.amount, specifier: "%.2f")")
                }
            }

            Spacer()
        }
        .padding()
        .navigationTitle(activity.name)
    }
}



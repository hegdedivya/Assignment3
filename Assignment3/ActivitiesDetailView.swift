//
//  ActivitiesDetailView.swift
//  Assignment3
//
//  Created by 安雨馨 on 2025/5/7.
//
import SwiftUI

struct ActivityDetailView: View {
    var activity: Activity
    
    var body: some View {
        VStack {
            Text(activity.name)
                .font(.title)
                .padding()
            
            Text("Date: \(activity.date.formatted(date: .long, time: .omitted))")
                .font(.headline)
            
            List {
                ForEach(activity.expenses, id: \.itemName) { expense in
                    HStack {
                        Text(expense.itemName)
                        Spacer()
                        Text("$\(String(format: "%.2f", expense.amount))")
                            .font(.headline)
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(PlainListStyle())
            
            Spacer()
        }
        .navigationTitle(activity.name)
    }
}

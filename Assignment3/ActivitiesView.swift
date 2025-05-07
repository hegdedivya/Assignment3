//
//  ActivitiesView.swift
//  Assignment3
//
//  Created by 安雨馨 on 2025/5/7.
//
import SwiftUI
import FirebaseFirestore
import Foundation

struct Expense: Identifiable, Codable {
    var id = UUID()
    var itemName: String
    var amount: Double
}

struct Activity: Identifiable, Codable {
    var id = UUID()
    var name: String
    var date: Date
    var members: [String]
    var expenses: [Expense]
}

struct ActivitiesView: View {
    @State private var activities: [Activity] = []
    @State private var isLoading = true

    var body: some View {
        NavigationView {
            if isLoading {
                ProgressView("Loading...")
            } else {
                List {
                    ForEach(activities) { activity in
                        NavigationLink(destination: ActivityDetailView(activity: activity)) {
                            VStack(alignment: .leading) {
                                Text(activity.name)
                                    .font(.headline)
                                Text("Date: \(activity.date.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.subheadline)
                            }
                        }
                    }
                }
                .navigationTitle("Activities")
            }
        }
        .onAppear {
            fetchActivities()
        }
    }

    func fetchActivities() {
        let db = Firestore.firestore()
        db.collection("activities").getDocuments { snapshot, error in
            if let error = error {
                print("❌ Error fetching activities: \(error)")
                return
            }

            if let documents = snapshot?.documents {
                activities = documents.compactMap { doc in
                    try? doc.data(as: Activity.self)
                }
                isLoading = false
            }
        }
    }
}


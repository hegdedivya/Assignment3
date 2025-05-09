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
    var id: String
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

            guard let documents = snapshot?.documents else {
                print("⚠️ No documents found")
                return
            }

            var fetchedActivities: [Activity] = []

            for doc in documents {
                let data = doc.data()
                let id = doc.documentID

                guard let name = data["name"] as? String,
                      let timestamp = data["date"] as? Timestamp,
                      let members = data["members"] as? [String],
                      let expenseArray = data["expenses"] as? [[String: Any]] else {
                    print("❌ Skipping invalid document: \(doc.documentID)")
                    continue
                }

                let date = timestamp.dateValue()

                // Parse expenses
                let expenses: [Expense] = expenseArray.compactMap { dict in
                    guard let itemName = dict["itemName"] as? String,
                          let amount = dict["amount"] as? Double else {
                        return nil
                    }
                    return Expense(itemName: itemName, amount: amount)
                }

                let activity = Activity(id: id, name: name, date: date, members: members, expenses: expenses)
                fetchedActivities.append(activity)
            }

            DispatchQueue.main.async {
                self.activities = fetchedActivities
                self.isLoading = false
            }
        }
    }

}

#Preview {
    NavigationView{
        ActivitiesView()
    }
}

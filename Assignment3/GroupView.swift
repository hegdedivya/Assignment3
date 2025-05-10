//
//  GroupView.swift
//  Assignment3
//
//  Created by 安雨馨 on 2025/5/7.
//
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct GroupView: View {
    @State private var groups: [Group] = [] // List of groups the user belongs to
    @State private var isAddGroupPresented: Bool = false // Modal for adding a group

    private let db = Firestore.firestore()
    private let currentUserId = Auth.auth().currentUser?.uid ?? "userId1" // Replace with actual user ID

    var body: some View {
        NavigationView {
            VStack {
                // Header
                Text("My Groups")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()

                // List of Groups
                List(groups) { group in
                    NavigationLink(destination: GroupDetailView(group: group)) {
                        Text(group.name)
                            .font(.headline)
                    }
                }
                .listStyle(PlainListStyle())

                Spacer()

                // Add Group Button
                Button(action: {
                    isAddGroupPresented = true
                }) {
                    Text("Add Group")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
                .sheet(isPresented: $isAddGroupPresented) {
                    AddGroupView(onGroupAdded: fetchGroups)
                }
            }
            .onAppear(perform: fetchGroups)
            .navigationTitle("Groups")
        }
    }

    // Fetch groups where the current user is a member
    func fetchGroups() {
        db.collection("groups")
            .whereField("members", arrayContains: currentUserId) // Query groups containing the current user
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching groups: \(error)")
                    return
                }

                guard let documents = snapshot?.documents else { return }

                self.groups = documents.compactMap { try? $0.data(as: Group.self) }
            }
    }
}

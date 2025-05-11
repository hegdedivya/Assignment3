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
    @State private var groups: [Group] = [] // List of groups
    @State private var isAddGroupPresented: Bool = false // Add group modal
    private let db = Firestore.firestore()
    private let currentUserId = Auth.auth().currentUser?.uid ?? "userId1" // Replace with actual user ID

    var body: some View {
        NavigationView {
            VStack {
                Text("My Groups")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()

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
                    AddGroupWithUsersView(onGroupAdded: fetchGroups)
                }
            }
            .onAppear(perform: fetchGroups)
            .navigationTitle("Groups")
        }
    }

    func fetchGroups() {
        db.collection("groups")
            .whereField("members", arrayContains: currentUserId)
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

struct GroupView_Previews: PreviewProvider {
    static var previews: some View {
        GroupView()
    }
}

//
//  AddUserToGroupView.swift
//  Assignment3
//
//  Created by Krithik on 10/5/2025.
//

import SwiftUI
import FirebaseFirestore

struct AddUserToGroupView: View {
    @Environment(\.dismiss) var dismiss
    @State private var searchQuery: String = "" // User's search query
    @State private var searchResults: [User] = [] // Search results
    @State private var selectedUser: User? // Selected user to add

    let group: Group
    private let db = Firestore.firestore()

    var body: some View {
        VStack {
            Text("Add User to \(group.name)")
                .font(.title)
                .padding()

            // Search Field
            TextField("Search by email or name", text: $searchQuery, onCommit: searchUsers)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            // Search Results
            List(searchResults) { user in
                Button(action: {
                    selectedUser = user
                }) {
                    HStack {
                        Text(user.name)
                        Spacer()
                        Text(user.email)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }

            Spacer()

            // Add User Button
            if let selectedUser = selectedUser {
                Button(action: {
                    addUserToGroup(user: selectedUser)
                }) {
                    Text("Add \(selectedUser.name)")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
        }
        .padding()
    }

    // Search for users by email or name
    func searchUsers() {
        db.collection("users")
            .whereField("email", isEqualTo: searchQuery)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error searching users: \(error)")
                    return
                }

                guard let documents = snapshot?.documents else { return }
                searchResults = documents.compactMap { try? $0.data(as: User.self) }
            }
    }

    // Add the selected user to the group
    func addUserToGroup(user: User) {
        guard let groupId = group.id else { return }

        // Update the group's `members` field
        db.collection("groups").document(groupId).updateData([
            "members": FieldValue.arrayUnion([user.id])
        ]) { error in
            if let error = error {
                print("Error adding user to group: \(error)")
                return
            }
            dismiss()
        }
    }
}

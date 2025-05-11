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
    @State private var searchQuery: String = ""
    @State private var searchResults: [User] = [] // Search results
    @State private var selectedUser: User? // Selected user to add

    let group: Group
    private let db = Firestore.firestore()

    var body: some View {
        VStack {
            Text("Add User to \(group.name)")
                .font(.title)
                .padding()

            TextField("Search by email or name", text: $searchQuery, onCommit: searchUsers)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            if searchResults.isEmpty && !searchQuery.isEmpty {
                Text("No user found. Would you like to invite them?")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .padding()

                Button(action: inviteUser) {
                    Text("Invite \(searchQuery)")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }

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

    func inviteUser() {
        print("Sending invite to \(searchQuery)...")
        // Logic to send an invite (e.g., via email or SMS)
    }

    func addUserToGroup(user: User) {
        guard let groupId = group.id else { return }

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

//
//  AddUsersToNewGroupView.swift
//  Assignment3
//
//  Created by Krithik on 11/5/2025.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct AddUsersToNewGroupView: View {
    @Environment(\.dismiss) var dismiss
    let groupName: String
    var onGroupAdded: () -> Void

    @State private var searchQuery: String = ""
    @State private var searchResults: [User] = []
    @State private var selectedUsers: [User] = []

    private let db = Firestore.firestore()
    private let currentUserId = Auth.auth().currentUser?.uid ?? "userId1"

    var body: some View {
        VStack {
            Text("Add Users to \(groupName)")
                .font(.title2)
                .padding()

            // Search field
            TextField("Search by email", text: $searchQuery, onCommit: searchUsers)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            // Search results
            List(searchResults) { user in
                HStack {
                    VStack(alignment: .leading) {
                        Text(user.name)
                        Text(user.email)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    if !selectedUsers.contains(where: { $0.id == user.id }) {
                        Button(action: {
                            selectedUsers.append(user)
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                                .imageScale(.large)
                        }
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .imageScale(.large)
                    }
                }
                .padding(.vertical, 4)
            }

            Divider()
                .padding(.top)

            // Selected users
            Text("Selected Users")
                .font(.headline)
                .padding(.top)

            List(selectedUsers) { user in
                HStack {
                    Text(user.name)
                    Spacer()
                    Button(action: {
                        selectedUsers.removeAll { $0.id == user.id }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.red)
                    }
                }
            }

            Spacer()

            // Create group button
            Button(action: createGroup) {
                Text("Create Group")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedUsers.isEmpty ? Color.gray : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            .disabled(selectedUsers.isEmpty)
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

    func createGroup() {
        let newGroupId = UUID().uuidString
        let memberIds = selectedUsers.map { $0.id } + [currentUserId]

        let groupData: [String: Any] = [
            "name": groupName,
            "members": memberIds,
            "createdAt": FieldValue.serverTimestamp()
        ]

        db.collection("groups").document(newGroupId).setData(groupData) { error in
            if let error = error {
                print("Error creating group: \(error)")
                return
            }

            onGroupAdded()
            dismiss()
        }
    }
}

//
//  AddGroupModal.swift
//  Assignment3
//
//  Created by Krithik on 10/5/2025.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct AddGroupView: View {
    @Environment(\.dismiss) var dismiss
    @State private var groupName: String = ""
    private let db = Firestore.firestore()
    private let currentUserId = Auth.auth().currentUser?.uid ?? "userId1" // Replace with actual user ID

    var onGroupAdded: () -> Void // Callback to refresh the group list

    var body: some View {
        VStack {
            Text("Add Group")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()

            TextField("Group Name", text: $groupName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button(action: addGroup) {
                Text("Create Group")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            .disabled(groupName.isEmpty) // Disable button if group name is empty

            Spacer()
        }
        .padding()
    }

    func addGroup() {
        let newGroupId = UUID().uuidString // Generate a unique ID for the group
        let groupData: [String: Any] = [
            "name": groupName,
            "members": [currentUserId], // Add current user as the first member
            "createdAt": FieldValue.serverTimestamp()
        ]

        // Write group data to Firestore
        db.collection("groups").document(newGroupId).setData(groupData) { error in
            if let error = error {
                print("Error creating group: \(error)")
                return
            }

            // Callback to refresh groups and dismiss the modal
            onGroupAdded()
            dismiss()
        }
    }
}

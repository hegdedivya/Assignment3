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
        @Binding var selectedGroup: Group? // First parameter
        private let db = Firestore.firestore()
        private let currentUserId = Auth.auth().currentUser?.uid ?? "userId1"

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
            .disabled(groupName.isEmpty)

            Spacer()
        }
        .padding()
    }

    func addGroup() {
        let newGroupId = UUID().uuidString
        let groupData: [String: Any] = [
            "name": groupName,
            "members": [currentUserId],
            "createdAt": FieldValue.serverTimestamp()
        ]

        db.collection("groups").document(newGroupId).setData(groupData) { error in
            if let error = error {
                print("Error creating group: \(error)")
                return
            }

            db.collection("groups").document(newGroupId).getDocument { snapshot, error in
                if let error = error {
                    print("Error fetching new group: \(error)")
                    return
                }

                guard let group = try? snapshot?.data(as: Group.self) else { return }

                selectedGroup = group
                onGroupAdded()
                dismiss()
            }
        }
    }
}

struct AddGroupView_Previews: PreviewProvider {
    static var previews: some View {
        AddGroupView(selectedGroup: .constant(nil), onGroupAdded: {})

    }
}

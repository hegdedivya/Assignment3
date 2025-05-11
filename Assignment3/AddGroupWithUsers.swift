//
//  AddGroupModal.swift
//  Assignment3
//
//  Created by Krithik on 10/5/2025.
//

import SwiftUI

struct AddGroupWithUsersView: View {
    @Environment(\.dismiss) var dismiss
    @State private var groupName: String = ""
    @State private var navigateToAddUsers = false

    var onGroupAdded: () -> Void

    var body: some View {
        NavigationView {
            VStack {
                Text("Create Group")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()

                // Group Name Input
                TextField("Group Name", text: $groupName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Spacer()

                NavigationLink(
                    destination: AddUsersToNewGroupView(
                        groupName: groupName,
                        onGroupAdded: onGroupAdded
                    ),
                    isActive: $navigateToAddUsers
                ) {
                    Button(action: {
                        navigateToAddUsers = true
                    }) {
                        Text("Next")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(groupName.isEmpty ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding()
                    .disabled(groupName.isEmpty)
                }
            }
            .padding()
        }
    }
}

struct AddGroupWithUsersView_Previews: PreviewProvider {
    static var previews: some View {
        AddGroupWithUsersView(onGroupAdded: {})
    }
}

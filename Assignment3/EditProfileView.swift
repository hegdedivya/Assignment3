//
//  EditProfileView.swift
//  Assignment3
//
//  Created by Divya on 11/5/2025.
//

import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var user: UserModel
    var onSave: (UserModel) -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Name")) {
                    TextField("First Name", text: $user.firstName)
                    TextField("Last Name", text: $user.lastName)
                }

                Section(header: Text("Phone")) {
                    TextField("Phone Number", text: $user.phoneNumber)
                }

                Section {
                    Button("Save Changes") {
                        onSave(user)
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.primaryYellow)
                    .cornerRadius(10)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
        }
    }
}

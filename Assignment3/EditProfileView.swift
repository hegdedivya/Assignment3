//
//  EditProfileView.swift
//  Assignment3
//
//  Created by Divya on 11/5/2025.
//

import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: UserProfileViewModel
    @State var user: User

    var body: some View {
        NavigationView {
                Form {
                    Section(header: Text("Personal Info")) {
                        TextField("First Name", text: $user.firstName)
                            .padding()
                        TextField("Last Name", text: $user.lastName)
                            .padding()
                    }
                    Section(header: Text("Contact")) {
                        TextField("Email", text: $user.email)
                            .padding()
                        TextField("Phone Number", text: $user.phoneNumber)
                            .padding()
                            .keyboardType(.phonePad)
                            
                        
                    }
                    
                }.background(Color.lightYellow)
            
            
            .navigationTitle("Edit Profile")
            
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.updateUser(updatedUser: user)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .background(Color.lightYellow)
        }
    }
}


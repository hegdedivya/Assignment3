//
//  AddFriendView.swift
//  Assignment3
//
//  Created by Minkun He on 9/5/2025.
//

import SwiftUI

struct AddFriendView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = FriendViewModel()
    @State private var searchEmail = ""
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Enter email to search for users", text: $searchEmail)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .padding()
                
                Button("Search") {
                    viewModel.searchUserByEmail(searchEmail)
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 10)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                if viewModel.isSearching {
                    ProgressView()
                        .padding()
                } else if !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage)
                        .foregroundColor(.red)
                        .padding()
                } else {
                    List {
                        ForEach(viewModel.searchResults) { user in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(user.name)
                                        .font(.headline)
                                    Text(user.email)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                Button("Add") {
                                    addFriend(user)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Add Friend")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
        }
    }
    
    func addFriend(_ friend: Friend) {
        viewModel.addFriend(friend) { success, errorMessage in
            if success {
                dismiss()
            } else if let errorMessage = errorMessage {
                viewModel.errorMessage = errorMessage
            }
        }
    }
}

struct AddFriendView_Previews: PreviewProvider {
    static var previews: some View {
        AddFriendView()
    }
}

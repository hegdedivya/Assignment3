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
    @State private var searchResults: [UserSearchResult] = []
    @State private var selectedUser: UserSearchResult?
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var searchType: SearchType = .email
    
    let group: Group
    @ObservedObject private var dataManager = FirebaseDataManager.shared
    
    var onUserAdded: () -> Void = {}
    
    enum SearchType {
        case email, phone
    }
    
    struct UserSearchResult: Identifiable {
        let id: String
        let name: String
        let email: String
        let phoneNumber: String?
    }
    
    var body: some View {
        VStack {
            // Header
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text("Add User to \(group.name)")
                    .font(.headline)
                
                Spacer()
            }
            .padding()
            
            // Search type selector
            Picker("Search Type", selection: $searchType) {
                Text("Email").tag(SearchType.email)
                Text("Phone").tag(SearchType.phone)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField(searchType == .email ? "Search by email" : "Search by phone", text: $searchQuery)
                    .keyboardType(searchType == .phone ? .phonePad : .emailAddress)
                    .autocapitalization(.none)
                
                Button(action: searchUsers) {
                    Text("Search")
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.blue, lineWidth: 1)
                        )
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            .padding(.horizontal)
            
            if isSearching {
                ProgressView()
                    .padding()
            }
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
            
            if searchResults.isEmpty && !searchQuery.isEmpty && !isSearching {
                Text("No user found with this \(searchType == .email ? "email" : "phone number").")
                    .padding()
            }
            
            List(searchResults) { user in
                Button(action: {
                    selectedUser = user
                }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(user.name)
                            Text(user.email)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        if selectedUser?.id == user.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())
            
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
    }
    
    func searchUsers() {
        guard !searchQuery.isEmpty else { return }
        
        isSearching = true
        errorMessage = nil
        
        let field = searchType == .email ? "email" : "phoneNumber"
        let db = Firestore.firestore()
        
        db.collection("users")
            .whereField(field, isEqualTo: searchQuery)
            .getDocuments { snapshot, error in
                isSearching = false
                
                if let error = error {
                    errorMessage = "Error searching users: \(error.localizedDescription)"
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    errorMessage = "No user found with this \(searchType == .email ? "email" : "phone number")"
                    return
                }
                
                // Filter out users already in the group
                self.searchResults = documents.compactMap { doc -> UserSearchResult? in
                    let data = doc.data()
                    
                    // Skip if user is already in the group
                    if group.members.contains(doc.documentID) {
                        errorMessage = "This user is already in the group"
                        return nil
                    }
                    
                    guard let firstName = data["firstName"] as? String,
                          let lastName = data["lastName"] as? String,
                          let email = data["email"] as? String else {
                        return nil
                    }
                    
                    return UserSearchResult(
                        id: doc.documentID,
                        name: "\(firstName) \(lastName)",
                        email: email,
                        phoneNumber: data["phoneNumber"] as? String
                    )
                }
            }
    }
    
    func addUserToGroup(user: UserSearchResult) {
        guard let groupID = group.id else {
            errorMessage = "Invalid group ID"
            return
        }
        
        isSearching = true
        
        dataManager.addUserToGroup(groupID: groupID, userID: user.id) { success, error in
            isSearching = false
            
            if success {
                onUserAdded()
                dismiss()
            } else if let error = error {
                errorMessage = error
            }
        }
    }
}

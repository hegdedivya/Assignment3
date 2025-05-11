//
//  AddUsersToNewGroupView.swift
//  Assignment3
//
//  Created by Krithik on 11/5/2025.
//

import SwiftUI
import FirebaseFirestore

struct AddUsersToNewGroupView: View {
    @Environment(\.dismiss) var dismiss
    let groupName: String
    let groupType: String
    var onGroupAdded: () -> Void
    
    @State private var searchQuery: String = ""
    @State private var searchResults: [UserSearchResult] = []
    @State private var selectedUsers: [UserSearchResult] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    
    @State private var searchType: SearchType = .email
    
    @ObservedObject private var dataManager = FirebaseDataManager.shared
    
    enum SearchType {
        case email, phone
    }
    
    struct UserSearchResult: Identifiable, Hashable {
        let id: String
        let name: String
        let email: String
        let phoneNumber: String?
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        static func == (lhs: UserSearchResult, rhs: UserSearchResult) -> Bool {
            return lhs.id == rhs.id
        }
    }
    
    var body: some View {
        VStack {
            // Header
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "arrow.left")
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text("Add people to \(groupName)")
                    .font(.headline)
                
                Spacer()
                
                Button(action: createGroup) {
                    Text("Create")
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
                .disabled(selectedUsers.isEmpty)
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
            
            // Search type selector
            Picker("Search Type", selection: $searchType) {
                Text("Email").tag(SearchType.email)
                Text("Phone").tag(SearchType.phone)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.bottom, 10)
            
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField(searchType == .email ? "Search by email" : "Search by phone number",
                          text: $searchQuery)
                    .keyboardType(searchType == .phone ? .phonePad : .emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                
                Button(action: searchUsers) {
                    Text("Search")
                        .foregroundColor(.blue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.blue, lineWidth: 1)
                        )
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            .padding(.horizontal)
            
            // Error message
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }
            
            // Loading indicator
            if isSearching {
                ProgressView()
                    .padding()
            }
            
            // Search results and other content as needed...
            if !searchResults.isEmpty {
                List {
                    Section(header: Text("Search Results")) {
                        ForEach(searchResults) { user in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(user.name)
                                    Text(searchType == .email ? user.email : (user.phoneNumber ?? "No phone"))
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    toggleUserSelection(user)
                                }) {
                                    Image(systemName: isUserSelected(user) ?
                                          "checkmark.circle.fill" : "plus.circle")
                                        .foregroundColor(isUserSelected(user) ? .green : .blue)
                                        .font(.title2)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            
            // Selected users section
            if !selectedUsers.isEmpty {
                List {
                    Section(header: Text("Selected Users (\(selectedUsers.count))")) {
                        ForEach(selectedUsers) { user in
                            HStack {
                                Text(user.name)
                                
                                Spacer()
                                
                                Button(action: {
                                    removeUser(user)
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                        .font(.title3)
                                }
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .frame(height: min(CGFloat(selectedUsers.count * 50), 200))
            }
            
            Spacer()
        }
        .padding(.top)
    }
    
    // Helper functions
    
    func isUserSelected(_ user: UserSearchResult) -> Bool {
        return selectedUsers.contains(where: { $0.id == user.id })
    }
    
    func toggleUserSelection(_ user: UserSearchResult) {
        if isUserSelected(user) {
            removeUser(user)
        } else {
            selectedUsers.append(user)
        }
    }
    
    func removeUser(_ user: UserSearchResult) {
        selectedUsers.removeAll { $0.id == user.id }
    }
    
    func searchUsers() {
        guard !searchQuery.isEmpty else { return }
        
        isSearching = true
        errorMessage = nil
        searchResults = []
        
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
                    errorMessage = "No users found with this \(searchType == .email ? "email" : "phone number")"
                    return
                }
                
                self.searchResults = documents.compactMap { document in
                    let data = document.data()
                    guard let firstName = data["firstName"] as? String,
                          let lastName = data["lastName"] as? String,
                          let email = data["email"] as? String else {
                        return nil
                    }
                    
                    return UserSearchResult(
                        id: document.documentID,
                        name: "\(firstName) \(lastName)".trimmingCharacters(in: .whitespacesAndNewlines),
                        email: email,
                        phoneNumber: data["phoneNumber"] as? String
                    )
                }
                
                if searchResults.isEmpty {
                    errorMessage = "No valid users found with this \(searchType == .email ? "email" : "phone number")"
                }
            }
    }
    
    func createGroup() {
        guard !selectedUsers.isEmpty else {
            errorMessage = "Please select at least one user to add to the group"
            return
        }
        
        isSearching = true
        errorMessage = nil
        
        // Get member IDs from selected users
        let memberIds = selectedUsers.map { $0.id }
        
        // Use FirebaseDataManager to create the group
        dataManager.createGroup(
            name: groupName,
            type: groupType,
            members: memberIds
        ) { success, error in
            isSearching = false
            
            if success {
                onGroupAdded()
                dismiss()
            } else if let error = error {
                errorMessage = error
            } else {
                errorMessage = "An unknown error occurred"
            }
        }
    }
}

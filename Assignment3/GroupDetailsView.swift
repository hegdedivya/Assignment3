//
//  GroupDetailsView.swift
//  Assignment3
//
//  Created by Divya on 6/5/2025.
//

import SwiftUI
import FirebaseFirestore

struct GroupDetailView: View {
    var group: Group
    @State private var isAddUserPresented: Bool = false
    @State private var groupMembers: [UserProfile] = []
    @State private var isLoadingMembers = false
    @State private var errorMessage: String?
    
    @ObservedObject private var dataManager = FirebaseDataManager.shared
    
    var body: some View {
        VStack {
            // Group Header
            HStack(spacing: 16) {
                // Group icon
                ZStack {
                    Circle()
                        .fill(Color.teal.opacity(0.2))
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: getGroupIcon(type: group.type ?? "Other"))
                        .font(.system(size: 30))
                        .foregroundColor(.teal)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.name)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("\(group.members.count) members")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text("Created \(group.createdAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Members section
            VStack(alignment: .leading) {
                Text("Members")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top)
                
                if isLoadingMembers {
                    ProgressView("Loading members...")
                        .padding()
                } else if groupMembers.isEmpty {
                    Text("No members found")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List {
                        ForEach(groupMembers) { member in
                            HStack {
                                // Member avatar
                                Circle()
                                    .fill(Color.teal.opacity(0.8))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Text(String(member.fullName.prefix(1)))
                                            .foregroundColor(.white)
                                            .font(.system(size: 18, weight: .bold))
                                    )
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(member.fullName)
                                        .font(.headline)
                                    
                                    Text(member.email)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                if member.id == dataManager.getCurrentUserID() {
                                    Text("You")
                                        .font(.caption)
                                        .foregroundColor(.teal)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            RoundedRectangle(cornerRadius: 4)
                                                .stroke(Color.teal, lineWidth: 1)
                                        )
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            
            Spacer()
            
            // Add User Button
            Button(action: {
                isAddUserPresented = true
            }) {
                HStack {
                    Image(systemName: "person.badge.plus")
                    Text("Add User")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()
            .sheet(isPresented: $isAddUserPresented) {
                AddUserToGroupView(group: group)
            }
        }
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadGroupMembers()
        }
    }
    
    // Helper function to get an icon for group type
    func getGroupIcon(type: String) -> String {
        switch type.lowercased() {
        case "trip": return "airplane"
        case "home": return "house"
        case "couple": return "heart"
        default: return "list.bullet"
        }
    }
    
    // Load group member details
    func loadGroupMembers() {
        isLoadingMembers = true
        groupMembers = []
        errorMessage = nil
        
        let db = Firestore.firestore()
        let dispatchGroup = DispatchGroup() // Changed from 'group' to 'dispatchGroup'
        
        for memberID in group.members {
            dispatchGroup.enter() // Use dispatchGroup instead of group
            
            db.collection("users").document(memberID).getDocument { snapshot, error in
                defer { dispatchGroup.leave() } // Use dispatchGroup instead of group
                
                if let error = error {
                    print("Error loading member data: \(error.localizedDescription)")
                    return
                }
                
                guard let data = snapshot?.data() else { return }
                
                let firstName = data["firstName"] as? String ?? ""
                let lastName = data["lastName"] as? String ?? ""
                let email = data["email"] as? String ?? ""
                
                let member = UserProfile(
                    id: memberID,
                    email: email,
                    firstName: firstName,
                    lastName: lastName,
                    phoneNumber: data["phoneNumber"] as? String ?? ""
                )
                
                DispatchQueue.main.async {
                    self.groupMembers.append(member)
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) { // Use dispatchGroup instead of group
            self.isLoadingMembers = false
        }
    }
}

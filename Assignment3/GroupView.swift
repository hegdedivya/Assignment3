//
//  GroupView.swift
//  Assignment3
//
//  Created by 安雨馨 on 2025/5/7.
//
import SwiftUI
import FirebaseFirestore

struct GroupView: View {
    @ObservedObject private var dataManager = FirebaseDataManager.shared
    @State private var isAddGroupPresented: Bool = false
    
    var body: some View {
        NavigationView {
            VStack {
                if dataManager.isLoadingGroups {
                    ProgressView("Loading groups...")
                } else if dataManager.groups.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "person.3")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Groups Yet")
                            .font(.title)
                        
                        Text("Create a group to start splitting bills with friends")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                    }
                    .padding()
                } else {
                    // Group list
                    List {
                        ForEach(dataManager.groups, id: \.id) { group in
                            NavigationLink(destination: GroupDetailView(group: group)) {
                                HStack {
                                    // Group icon based on type
                                    Image(systemName: getGroupIcon(type: group.type ?? "Other"))
                                        .font(.title2)
                                        .foregroundColor(.teal)
                                        .frame(width: 40, height: 40)
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(8)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(group.name)
                                            .font(.headline)
                                        
                                        Text("\(group.members.count) members")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.leading, 8)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Add Group Button
                Button(action: {
                    isAddGroupPresented = true
                }) {
                    HStack {
                        Image(systemName: "plus")
                            .font(.headline)
                        Text("Add Group")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding()
                .sheet(isPresented: $isAddGroupPresented) {
                    AddGroupWithUsersView(onGroupAdded: {
                        // Refresh groups if needed, though Firebase listener should handle this
                        if let userID = dataManager.getCurrentUserID() {
                            dataManager.fetchUserGroups(userID: userID)
                        }
                    })
                }
            }
            .navigationTitle("Groups")
        }
        .onAppear {
            if let userID = dataManager.getCurrentUserID() {
                dataManager.fetchUserGroups(userID: userID)
            }
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
}

struct GroupView_Previews: PreviewProvider {
    static var previews: some View {
        GroupView()
    }
}

//
//  DashboardView.swift
//  Assignment3
//
//  Created by 安雨馨 on 2025/5/7.
//
 
import SwiftUI
 
struct DashboardView: View {
    @ObservedObject private var dataManager = FirebaseDataManager.shared
    
    var body: some View {
        TabView {
            GroupView()
                .tabItem {
                    Label("Group", systemImage: "person.3.fill")
                }
            FriendView()
                .tabItem {
                    Label("Friends",systemImage: "person.2.fill")
                }
            
            
            // Always show UserProfileView with current user ID
            if let userID = dataManager.getCurrentUserID() {
                UserProfileView(userId: userID)
                    .tabItem {
                        Label("Account", systemImage: "person.crop.circle")
                    }
            } else {
                // Fallback view while user data is loading
                VStack {
                    ProgressView("Loading profile...")
                    Text("Please wait...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .tabItem {
                    Label("Account", systemImage: "person.crop.circle")
                }
            }
        }
    }
}
 
#Preview {
    DashboardView()
}
 

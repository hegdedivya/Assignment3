//
//  Dashboard.swift
//  Assignment3
//
//  Created by 安雨馨 on 2025/5/7.
//

import SwiftUI

struct DashboardView: View {
    let dataManager = FirebaseDataManager.shared
    var body: some View {
        let userID = dataManager.getCurrentUserID()
        TabView {
            GroupView()
                .tabItem {
                    Label("Group", systemImage: "person.3.fill")
                }
            FriendView()
                .tabItem {
                    Label("Friends",systemImage: "person.2.fill")
                }
            ActivitiesView()
                .tabItem {
                    Label("Activities", systemImage: "list.bullet.rectangle")
                
                }
            if let userID = dataManager.getCurrentUserID() {
                            UserProfileView(userId: userID)
                                .tabItem {
                                    Label("Account", systemImage: "person.crop.circle")
                                }
            } else {
                // Show a placeholder or login prompt if there's no user ID
                Text("Please log in to view your profile")
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




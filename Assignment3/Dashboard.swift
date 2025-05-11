//
//  Dashboard.swift
//  Assignment3
//
//  Created by 安雨馨 on 2025/5/7.
//

import SwiftUI

struct DashboardView: View {
    var body: some View {
        TabView {
            ActivitiesView()
                .tabItem {
                    Label("Activities", systemImage: "list.bullet.rectangle")
                
                }
            FriendView()
                .tabItem {
                    Label("Friends",systemImage: "person.2.fill")
                }
            GroupView()
                .tabItem {
                    Label("Group", systemImage: "person.3.fill")
                }

                UserProfileView()
                    .tabItem {
                        Label("Account", systemImage: "person.crop.circle")
                    }
            
            
        }
    }
}

#Preview {
    DashboardView()
}

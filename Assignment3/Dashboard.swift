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
                    Label("Activities 123", systemImage: "list.bullet.rectangle")
                
                }

            GroupView()
                .tabItem {
                    Label("Group", systemImage: "person.3.fill")
                }

            AccountView()
                .tabItem {
                    Label("Account", systemImage: "person.crop.circle")
                }
        }
    }
}

#Preview {
    DashboardView()
}

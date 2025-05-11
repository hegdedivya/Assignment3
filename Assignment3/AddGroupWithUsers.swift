//
//  AddGroupModal.swift
//  Assignment3
//
//  Created by Krithik on 10/5/2025.
//

import SwiftUI

struct AddGroupWithUsersView: View {
    @Environment(\.dismiss) var dismiss
    @State private var groupName: String = ""
    @State private var selectedGroupType: GroupType = .trip
    @State private var showAddUsersSheet = false // Changed to use sheet instead of NavigationLink
    
    var onGroupAdded: () -> Void
    
    enum GroupType: String, CaseIterable {
        case trip = "Trip"
        case home = "Home"
        case couple = "Couple"
        case other = "Other"
        
        var icon: String {
            switch self {
            case .trip: return "airplane"
            case .home: return "house"
            case .couple: return "heart"
            case .other: return "list.bullet"
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header with close button and title
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text("Create a group")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                    if !groupName.isEmpty {
                        showAddUsersSheet = true
                    }
                }) {
                    Text("Next")
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                .disabled(groupName.isEmpty)
            }
            .padding(.bottom, 20)
            
            // Group image and name
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "camera")
                        .font(.system(size: 28))
                        .foregroundColor(.gray)
                }
                
                VStack(alignment: .leading) {
                    Text("Group name")
                        .font(.headline)
                    
                    TextField("Enter group name", text: $groupName)
                        .padding(.vertical, 8)
                }
            }
            
            // Group type selection
            Text("Type")
                .font(.headline)
                .padding(.top, 12)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(GroupType.allCases, id: \.self) { type in
                    Button(action: {
                        selectedGroupType = type
                    }) {
                        HStack {
                            Image(systemName: type.icon)
                                .font(.system(size: 18))
                            
                            Text(type.rawValue)
                                .fontWeight(.medium)
                            
                            Spacer()
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(selectedGroupType == type ? Color.blue : Color.gray.opacity(0.3), lineWidth: selectedGroupType == type ? 2 : 1)
                        )
                    }
                }
            }
            
            Spacer()
            
            // Bottom next button for extra clarity
            Button(action: {
                if !groupName.isEmpty {
                    showAddUsersSheet = true
                }
            }) {
                Text("Continue to Add Users")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(groupName.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(groupName.isEmpty)
            .padding(.bottom)
        }
        .padding()
        // Use sheet presentation instead of NavigationLink
        .sheet(isPresented: $showAddUsersSheet) {
            AddUsersToNewGroupView(
                groupName: groupName,
                groupType: selectedGroupType.rawValue,
                onGroupAdded: onGroupAdded
            )
        }
    }
}

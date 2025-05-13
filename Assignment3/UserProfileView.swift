//
//  UserProfileView.swift
//  Assignment3
//
//  Created by Divya on 11/5/2025.
//

import SwiftUI
import FirebaseAuth

struct UserProfileView: View {
    let userId: String
    @StateObject private var viewModel = UserProfileViewModel()
    @State private var showEditView = false
    @State private var showLogoutAlert = false
    
    // Access the shared data manager
    @ObservedObject private var dataManager = FirebaseDataManager.shared

    var body: some View {
        NavigationView {
            ZStack {
                Color.yellow.opacity(0.1)
                    .ignoresSafeArea()
                VStack {
                    if let user = viewModel.user {
                        Image("Logo")
                            .resizable()
                            .frame(width: 150, height: 150)
                            .foregroundColor(.primaryYellow)
                            .padding()

                        Text("\(user.firstName) \(user.lastName)")
                            .font(.title)
                            .bold()
                            .padding()

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "phone")
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(Color.primaryYellow)
                                    .clipShape(Circle())
                                Text("Phone: \(user.phoneNumber)")
                                    .padding()
                            }
                            Divider()
                            HStack {
                                Image(systemName: "envelope")
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(Color.primaryYellow)
                                    .clipShape(Circle())
                                Text("Email: \(user.email)")
                                    .padding()
                            }
                            Divider()
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(Color.primaryYellow)
                                    .clipShape(Circle())
                                Text("Joined: \(user.createdAt.formatted(date: .abbreviated, time: .shortened))")
                                    .padding()
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(20)
                        .padding(.horizontal)

                    } else {
                        ProgressView("Loading...")
                    }

                    // Buttons section
                    VStack(spacing: 16) {
                        Button("Edit Profile") {
                            showEditView = true
                        }
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.primaryYellow)
                        .cornerRadius(10)
                        
                        Button("Logout") {
                            showLogoutAlert = true
                        }
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.red)
                        .cornerRadius(10)
                    }
                    .padding()
                    
                    .sheet(isPresented: $showEditView) {
                        if let user = viewModel.user {
                            EditProfileView(viewModel: viewModel, user: user)
                        }
                    }
                    .alert("Logout", isPresented: $showLogoutAlert) {
                        Button("Cancel", role: .cancel) { }
                        Button("Logout", role: .destructive) {
                            logout()
                        }
                    } message: {
                        Text("Are you sure you want to logout?")
                    }
                }
                .navigationTitle("Profile")
            }
            .onAppear {
                viewModel.fetchUser(withId: userId)
            }
        }
    }
    
    private func logout() {
        // Clear user data from data manager
        dataManager.clearUserData()
        
        // Sign out from Firebase Auth
        do {
            try Auth.auth().signOut()
        } catch let signOutError as NSError {
            print("Error signing out: \(signOutError.localizedDescription)")
        }
    }
}

#Preview {
    UserProfileView(userId: "sampleUserID")
}

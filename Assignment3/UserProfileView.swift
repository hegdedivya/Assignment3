//
//  UserProfileView.swift
//  Assignment3
//
//  Created by Divya on 6/5/2025.
//

import SwiftUI

struct UserProfileView: View {
    @StateObject private var viewModel = UserProfileViewModel()
    @State private var showEdit = false
    @State private var editableUser: UserModel = UserModel(id: nil, firstName: "", lastName: "", email: "", phoneNumber: "", createdAt: Date())

    let userId: String

    var body: some View {
        ZStack {
            Color.lightYellow.ignoresSafeArea()

            if let user = viewModel.user {
                ScrollView {
                    VStack(spacing: 24) {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 120, height: 120)
                            .foregroundColor(.primaryYellow)

                        Text(user.fullName)
                            .font(.title)
                            .foregroundColor(.primaryYellow)

                        UserDetailCard(iconName: "envelope", title: "Email", value: user.email)
                        UserDetailCard(iconName: "phone", title: "Phone", value: user.phoneNumber)
                        UserDetailCard(iconName: "calendar", title: "Joined", value: user.createdAt.formatted(date: .abbreviated, time: .shortened))

                        Button("Edit Profile") {
                            editableUser = user
                            showEdit = true
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.primaryYellow)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                    .padding()
                }
                .fullScreenCover(isPresented: $showEdit) {
                    EditProfileView(user: $editableUser) { updatedUser in
                        viewModel.updateUser(updatedUser) { success in
                            if success {
                                showEdit = false
                            }
                        }
                    }
                }
            } else {
                ProgressView("Loading...")
            }
        }
        .onAppear {
            viewModel.fetchUser(withId: userId)
        }
    }
}
#Preview {
    UserProfileView(userId: "0Osua46bIQOVxdrx5fP3D4qNmKB2")
}

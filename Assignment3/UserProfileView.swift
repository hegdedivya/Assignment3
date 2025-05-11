import SwiftUI

struct UserProfileView: View {
    let userId: String
    @StateObject private var viewModel = UserProfileViewModel()
    @State private var showEditView = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.yellow.opacity(0.1)
                    .ignoresSafeArea()
                VStack {
                    if let user = viewModel.user {
                        Image(systemName: "person.crop.circle")
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

                    Button("Edit Profile") {
                        showEditView = true
                    }
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.primaryYellow)
                    .cornerRadius(10)
                    .padding()
                    .sheet(isPresented: $showEditView) {
                        if let user = viewModel.user {
                            EditProfileView(viewModel: viewModel, user: user)
                        }
                    }
                }
                .navigationTitle("Profile")
            }
            .onAppear {
                viewModel.fetchUser(withId: userId)
            }
        }
    }
}

#Preview {
    UserProfileView(userId: "sampleUserID")
}

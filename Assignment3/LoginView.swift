//
//  LoginView.swift
//  Assignment3
//
//  Created by 安雨馨 on 2025/5/7.
//

import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoggedIn = false
    @State private var isLoading = false
    
    // Access the shared data manager
    @ObservedObject private var dataManager = FirebaseDataManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Log In")
                .font(.largeTitle)
                .bold()
            
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                Button(action: loginUser) {
                    Text("Log in")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            NavigationLink(destination: DashboardView(), isActive: $isLoggedIn) {
                EmptyView()
            }
            
            NavigationLink(destination: RegisterView()) {
                Text("Don't have an account? Register")
                    .font(.footnote)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .onReceive(dataManager.$currentUser) { user in
            if user != nil && isLoading {
                isLoading = false
                isLoggedIn = true
            }
        }
        .onChange(of: dataManager.errorMessage) { newValue in
            if let error = newValue, isLoading {
                errorMessage = error
                isLoading = false
            }
        }
    }
    
    func loginUser() {
        guard !email.isEmpty && !password.isEmpty else {
            errorMessage = "Please enter both email and password"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                // Handle login error
                isLoading = false
                errorMessage = error.localizedDescription
            } else {
                // Successful login - fetch user data
                // The navigation will happen when user data is loaded via onChange
                dataManager.fetchUserDataAfterLogin()
            }
        }
    }
}

#Preview {
    NavigationView {
        LoginView()
    }
}

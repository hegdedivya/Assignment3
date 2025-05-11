//
//  LoginView.swift
//  Assignment3
//
//  Created by 安雨馨 on 2025/5/7.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var userID: String? = nil  // Use optional String to track navigation
    
    var body: some View {
        NavigationStack {
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
                
                Button(action: loginUser) {
                    Text("Log in")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                NavigationLink(destination: RegisterView()) {
                    Text("Don't have an account? Register")
                        .font(.footnote)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .navigationDestination(isPresented: Binding(
                get: { userID != nil },
                set: { _ in }
            )) {
                if let uid = userID {
                    DashboardView(userID: uid)
                }
            }
        }
    }
    
    func loginUser() {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
            } else if let user = result?.user {
                let uid = user.uid
                let db = Firestore.firestore()
                db.collection("users").document(uid).getDocument { document, error in
                    if let document = document, document.exists {
                        self.userID = document.documentID
                    } else {
                        self.errorMessage = "User document not found."
                    }
                }
            }
        }
    }
}
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}

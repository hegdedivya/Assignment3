//
//  RegisterView.swift
//  Assignment3
//
//  Created by 安雨馨 on 2025/5/7.
//
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct RegisterView: View {
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phoneNumber = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    @State private var isRegistered = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Register")
                .font(.largeTitle)
                .bold()
            
            TextField("First Name", text: $firstName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("Last Name", text: $lastName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
            
            TextField("Phone Number", text: $phoneNumber)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.phonePad)
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            SecureField("Confirm Password", text: $confirmPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button(action: registerUser) {
                Text("Sign Up")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            NavigationLink(destination: LoginView(), isActive: $isRegistered) {
                EmptyView()
            }
        }
        .padding()
    }
    
    func registerUser() {
        guard phoneNumber.count == 10, phoneNumber.allSatisfy({ $0.isNumber }) else {
                errorMessage = "Cell phone number with more than 10 digits"
                return
            }
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }
        let db = Firestore.firestore()
        db.collection("users").whereField("phoneNumber", isEqualTo: phoneNumber).getDocuments { (snapshot, error) in
            if let error = error {
                self.errorMessage = "Error in checking phone number：\(error.localizedDescription)"
                return
            }
            
            if let snapshot = snapshot, !snapshot.documents.isEmpty {
                // 已经存在相同手机号
                self.errorMessage = "This cell phone number already exists, please re-enter your cell phone number."
                return
            }
        }
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
            } else if let user = result?.user {
                let db = Firestore.firestore()
                db.collection("users").document(user.uid).setData([
                    "firstName": firstName,
                    "lastName": lastName,
                    "email": email,
                    "phoneNumber": phoneNumber,
                    "createdAt": Timestamp()
                ]) { err in
                    if let err = err {
                        errorMessage = "Failed to save user data: \(err.localizedDescription)"
                    } else {
                        errorMessage = ""
                        isRegistered = true
                    }
                }
            }
        }
    }
}
#Preview {
    NavigationView{
        RegisterView()
    }
}


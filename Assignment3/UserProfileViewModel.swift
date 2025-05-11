//
//  UserViewModel.swift
//  Assignment3
//
//  Created by Divya on 6/5/2025.
//


/*
struct User {
    var name: String
    var email: String
    var profileImageName: String // Assume it's in Assets
}

class UserViewModel: ObservableObject {
    @Published var user = User(name: "Jane Doe", email: "jane@example.com", profileImageName: "profile")
}
*/


import Foundation
import FirebaseFirestore

class UserProfileViewModel: ObservableObject {
    @Published var user: User?

    private var db = Firestore.firestore()

    func fetchUser(withId id: String) {
        db.collection("users").document(id).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching user: \(error)")
                return
            }

            guard let snapshot = snapshot, snapshot.exists,
                  let data = snapshot.data(),
                  let user = User(id: snapshot.documentID, data: data) else {
                print("Document does not exist or is malformed.")
                return
            }

            DispatchQueue.main.async {
                self.user = user
            }
        }
    }

    func updateUser(updatedUser: User) {
        db.collection("users").document(updatedUser.id).setData(updatedUser.dictionary) { error in
            if let error = error {
                print("Error updating user: \(error)")
            } else {
                DispatchQueue.main.async {
                    self.user = updatedUser
                }
                print("User successfully updated")
            }
        }
    }
}

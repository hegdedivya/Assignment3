//
//  UserViewModel.swift
//  Assignment3
//
//  Created by Divya on 6/5/2025.
//

import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable {
    @DocumentID var id: String? // Firestore document ID
    let name: String
    let email: String
    let profileImageName: String? // Optional profile picture URL
}

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


class UserProfileViewModel: ObservableObject {
    @Published var user: UserModel?

    private let db = Firestore.firestore()

    func fetchUser(withId id: String) {
        db.collection("users").document(id).getDocument { document, error in
            if let document = document, document.exists {
                do {
                    self.user = try document.data(as: UserModel.self)
                } catch {
                    print("Decoding error: \(error)")
                }
            }
        }
    }

    func updateUser(_ user: UserModel, completion: @escaping (Bool) -> Void) {
        guard let id = user.id else {
            completion(false)
            return
        }
        do {
            try db.collection("users").document(id).setData(from: user) { error in
                if let error = error {
                    print("Update error: \(error)")
                    completion(false)
                } else {
                    self.user = user
                    completion(true)
                }
            }
        } catch {
            print("Encoding error: \(error)")
            completion(false)
        }
    }
}

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

*/
class UserViewModel: ObservableObject {
    @Published var user = User(name: "Jane Doe", email: "jane@example.com", profileImageName: "profile")
}

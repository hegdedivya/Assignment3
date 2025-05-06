//
//  UserViewModel.swift
//  Assignment3
//
//  Created by Divya on 6/5/2025.
//

import Foundation

struct User {
    var name: String
    var email: String
    var profileImageName: String // Assume it's in Assets
}


class UserViewModel: ObservableObject {
    @Published var user = User(name: "Jane Doe", email: "jane@example.com", profileImageName: "profile")
}

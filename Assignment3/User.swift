//
//  User.swift
//  Assignment3
//
//  Created by Divya on 6/5/2025.
//

import Foundation
//import FirebaseFirestore

struct UserModel: Identifiable, Codable {
    var id: String?
    var firstName: String
    var lastName: String
    var email: String
    var phoneNumber: String
    var createdAt: Date

    var fullName: String {
        "\(firstName) \(lastName)"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case firstName
        case lastName
        case email
        case phoneNumber //= "Phone number"
        case createdAt
    }
}

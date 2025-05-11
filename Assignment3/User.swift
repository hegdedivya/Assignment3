//
//  User.swift
//  Assignment3
//
//  Created by Divya on 6/5/2025.
//

import Foundation
import FirebaseFirestore

struct User: Identifiable {
    var id: String
    var firstName: String
    var lastName: String
    var email: String
    var phoneNumber: String
    var createdAt: Date

    init?(id: String, data: [String: Any]) {
        guard let firstName = data["firstName"] as? String,
              let lastName = data["lastName"] as? String,
              let email = data["email"] as? String,
              let phoneNumber = data["phoneNumber"] as? String,
              let timestamp = data["createdAt"] as? Timestamp else {
            return nil
        }

        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phoneNumber = phoneNumber
        self.createdAt = timestamp.dateValue()
    }

    var dictionary: [String: Any] {
        return [
            "firstName": firstName,
            "lastName": lastName,
            "email": email,
            "phoneNumber": phoneNumber,
            "createdAt": Timestamp(date: createdAt)
        ]
    }
}


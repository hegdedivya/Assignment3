//
//  FriendModel.swift
//  Assignment3
//
//  Created by Minkun He on 9/5/2025.
//

import Foundation

struct Friend: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var email: String
    var imageURL: String?
    var amountOwed: Double // Positive means friend owes you, negative means you owe friend
    
    // Custom init to create a friend without an ID (will be assigned by Firestore)
    init(name: String, email: String, imageURL: String? = nil, amountOwed: Double = 0) {
        self.id = UUID().uuidString
        self.name = name
        self.email = email
        self.imageURL = imageURL
        self.amountOwed = amountOwed
    }
    
    // Init with ID (used when fetching from Firestore)
    init(id: String, name: String, email: String, imageURL: String? = nil, amountOwed: Double = 0) {
        self.id = id
        self.name = name
        self.email = email
        self.imageURL = imageURL
        self.amountOwed = amountOwed
    }
    
    static func == (lhs: Friend, rhs: Friend) -> Bool {
        return lhs.id == rhs.id
    }
}

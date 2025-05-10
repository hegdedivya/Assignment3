//
//  Group.swift
//  Assignment3
//
//  Created by Divya on 6/5/2025.
//


import FirebaseFirestore

struct Group: Identifiable, Codable {
    @DocumentID var id: String? // Firestore will automatically assign this
    let name: String
    let members: [String]
    let createdAt: Date

}

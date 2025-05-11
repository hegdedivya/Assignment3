//
//  Group.swift
//  Assignment3
//
//  Created by Divya on 6/5/2025.
//
import Foundation
import FirebaseFirestore

struct Group: Identifiable, Codable {
    @DocumentID var id: String?
    let name: String
    let members: [String]
    let createdAt: Date
    let type: String?
    let createdBy: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case members
        case createdAt
        case type
        case createdBy
    }
}

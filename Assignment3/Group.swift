//
//  Group.swift
//  Assignment3
//
//  Created by Divya on 6/5/2025.
//

import Foundation

struct Group: Identifiable, Codable {
    var id: String
    var name: String
    var members: [String]
    var createdAt: Date
}

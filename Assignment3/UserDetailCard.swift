//
//  UserDetailCard.swift
//  Assignment3
//
//  Created by Divya on 11/5/2025.
//

import SwiftUI

struct UserDetailCard: View {
    let iconName: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: iconName)
                .foregroundColor(.white)
                .padding(10)
                .background(Color.primaryYellow)
                .clipShape(Circle())

            VStack(alignment: .leading) {
                Text(title).font(.caption).foregroundColor(.gray)
                Text(value).font(.body)
            }
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}


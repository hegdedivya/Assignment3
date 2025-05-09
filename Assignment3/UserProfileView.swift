//
//  UserProfileView.swift
//  Assignment3
//
//  Created by Divya on 6/5/2025.
//

import SwiftUI

struct UserProfileView: View {
    var body: some View {
        ZStack() {
            Color.yellow
                .opacity(0.1)
                .ignoresSafeArea()
            VStack() {
                Text("Profile")
                    .font(.title)
                    .fontWeight(.black)
                    .padding()
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .foregroundColor(.pink)
                    .frame(width: 120, height: 120)
                    .padding(.top, 40)
                    .shadow(radius: 10)
                
                // Name & Email
                Text("John Doe")
                    .font(.title)
                    .bold()

                Text("john.doe@example.com")
                    .foregroundColor(.gray)
                    .padding()
                Text("0478937652")
                Divider().padding(.vertical)
                Text("SplitMe Pro")
                    .font(.title3)
                    .fontWeight(.bold)
                    .padding()
                Divider().padding(.vertical)
                Text("Privacy")
                    .font(.title3)
                    .fontWeight(.bold)
                    .padding()
                Divider().padding(.vertical)
                Text("Contact Us")
                    .font(.title3)
                    .fontWeight(.bold)
                    .padding()
                Divider().padding(.vertical)
                Text("Rate SplitMe")
                    .font(.title3)
                    .fontWeight(.bold)
            }
        }
        
        
        
    }
}

#Preview {
    UserProfileView()
}

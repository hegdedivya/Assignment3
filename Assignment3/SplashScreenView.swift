//
//  SplashScreenView.swift
//  Assignment3
//
//  Created by Your Name on 2025/5/13.
//

import SwiftUI

struct SplashScreenView: View {
    var body: some View {
        ZStack {
            // Background color - adjust as needed
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack {
                // Your app logo - replace with your actual logo
                Image(systemName: "app.badge") // Replace with your logo
                    .font(.system(size: 100))
                    .foregroundColor(.blue)
                
                // App name if you want to show it
                Text("Split Now")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 20)
            }
        }
    }
}

#Preview {
    SplashScreenView()
}

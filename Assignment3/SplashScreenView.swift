//
//  SplashScreenView.swift
//  Assignment3
//
//

import SwiftUI

struct SplashScreenView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack {
                Image("Logo")
                    .scaledToFit()
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

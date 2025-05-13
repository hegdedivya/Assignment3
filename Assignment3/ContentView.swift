//
//  ContentView.swift
//  Assignment3
//
//  Created by Divya on 23/4/2025.
//

//
//  ContentView.swift
//  Assignment3
//
//  Created by Your Name on 2025/5/13.
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @State private var showingSplash = true
    @State private var isLoggedIn = false
    @State private var checkingAuth = true
    
    // Access the shared data manager
    @ObservedObject private var dataManager = FirebaseDataManager.shared
    
    var body: some View {
        NavigationView {
            SwiftUI.Group {  // Use SwiftUI.Group to avoid conflict with your Group struct
                if showingSplash {
                    // Splash Screen
                    SplashScreenView()
                        .onAppear {
                            // Check authentication status after a brief delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                checkAuthenticationStatus()
                            }
                        }
                } else if checkingAuth {
                    // Loading state while checking auth
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.primary.colorInvert())
                } else {
                    // Navigate to appropriate view based on auth state
                    if isLoggedIn {
                        DashboardView()
                    } else {
                        LoginView()
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle()) // Ensure proper navigation on all devices
    }
    
    private func checkAuthenticationStatus() {
        // Check if user is already authenticated
        if let currentUser = Auth.auth().currentUser {
            // User is already logged in
            isLoggedIn = true
            
            // Fetch user data
            dataManager.fetchUserDataAfterLogin()
            
            // Wait a bit for user data to load, then hide splash
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                checkingAuth = false
                showingSplash = false
            }
        } else {
            // No user is logged in
            isLoggedIn = false
            checkingAuth = false
            showingSplash = false
        }
    }
}

#Preview {
    ContentView()
}

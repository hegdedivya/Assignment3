//
//  ContentView.swift
//  Assignment3
//
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
            SwiftUI.Group {
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
        .navigationViewStyle(StackNavigationViewStyle())
        // Listen for auth state changes
        .onReceive(dataManager.$currentUser) { user in
            if user != nil && !isLoggedIn {
                // User just logged in
                isLoggedIn = true
                checkingAuth = false
                showingSplash = false
            } else if user == nil && isLoggedIn {
                // User just logged out
                isLoggedIn = false
                checkingAuth = false
                showingSplash = false
            }
        }
    }
    
    private func checkAuthenticationStatus() {
        // Check if user is already authenticated
        if let currentUser = Auth.auth().currentUser {
            // User is already logged in
            
            // Fetch user data
            dataManager.fetchUserDataAfterLogin()
            
            // Wait a bit for user data to load, then navigate to dashboard
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                isLoggedIn = true
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

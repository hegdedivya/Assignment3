//
//  Assignment3App.swift
//  Assignment3
//
//  Created by Your Name on 2025/5/13.
//

import SwiftUI
import Firebase

@main
struct Assignment3App: App {
    
    // Initialize Firebase when the app starts
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView() // Set ContentView as the main entry point
        }
    }
}

//
//  Assignment3App.swift
//  Assignment3
//
//  Created by Divya on 23/4/2025.
//

import SwiftUI

@main
struct Assignment3App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            LoginView()
            //ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

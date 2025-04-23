//
//  Assignment3App.swift
//  Assignment3
//
//  Created by Divya on 23/4/2025.
//

import SwiftUI

@main
struct Assignment3App: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

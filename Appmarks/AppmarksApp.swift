//
//  AppmarksApp.swift
//  Appmarks
//
//  Created by Liam Cottle on 17/02/21.
//

import SwiftUI

@main
struct AppmarksApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

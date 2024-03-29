//
//  AppmarksApp.swift
//  Appmarks
//
//  Created by Liam Cottle on 17/02/21.
//

import SwiftUI
import AppmarksFramework

struct SharedUrlKey: EnvironmentKey {
    static var defaultValue: String? {
        return nil
    }
}

extension EnvironmentValues {
    var sharedUrl: String? {
        get {
            self[SharedUrlKey]
        }
        set {
            self[SharedUrlKey] = newValue
        }
    }
}

@main
struct AppmarksApp: App {
    
    @State var sharedUrl: String?
    let persistentContainer = CoreDataStack.sharedInstance.persistentContainer

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistentContainer.viewContext)
                .environment(\.sharedUrl, sharedUrl)
                .onOpenURL { url in
                    
                    // update shared url
                    self.sharedUrl = url.absoluteString
                    
                    
                    // unset shared url after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) {
                        self.sharedUrl = nil
                    }
                    
                }
        }
    }
}

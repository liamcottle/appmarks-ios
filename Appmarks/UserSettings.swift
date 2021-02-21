//
//  Settings.swift
//  Appmarks
//
//  Created by Liam Cottle on 21/02/21.
//

import Foundation
import Combine

@propertyWrapper
struct UserDefault<T> {
    let key: String
    let defaultValue: T
    
    init(_ key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }
    
    var wrappedValue: T {
        get {
            return UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }
}

public final class UserSettings: ObservableObject {

    public let objectWillChange = PassthroughSubject<Void, Never>()

    @UserDefault("has_seen_welcome_screen", defaultValue: false)
    var hasSeenWelcomeScreen: Bool {
        willSet {
            objectWillChange.send()
        }
    }
}

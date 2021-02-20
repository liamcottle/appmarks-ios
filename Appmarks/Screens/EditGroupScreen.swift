//
//  EditGroupScreen.swift
//  Appmarks
//
//  Created by Liam Cottle on 18/02/21.
//

import Foundation
import SwiftUI
import AppmarksFramework

struct EditGroupScreen: View {
    
    @Environment(\.managedObjectContext) var context
    
    @Binding var isShowing: Bool
    @ObservedObject var group: AppmarksFramework.Group
    
    @State var name: String
    
    init(isShowing: Binding<Bool>, group: AppmarksFramework.Group) {
        self._isShowing = isShowing
        self.group = group
        self._name = State(initialValue: group.name ?? "")
    }

    var body: some View {
        List {
            Section {
                TextField("Name", text: $name)
            }
        }
        .listStyle(GroupedListStyle())
        .navigationBarTitle("Edit Group", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel", action: {
                    isShowing = false
                })
            }
            ToolbarItem {
                Button("Done", action: {
                    saveGroup()
                })
            }
        }
    }
    
    func saveGroup() {
        
        // make sure a name is provided
        if name.isEmpty {
            name = "Unnamed Group"
        }
        
        // update group details
        group.name = name
        
        // save coredata
        try? context.save()
        
        // dismiss this screen
        isShowing = false
        
    }
    
}

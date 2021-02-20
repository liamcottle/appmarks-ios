//
//  CreateGroupScreen.swift
//  Appmarks
//
//  Created by Liam Cottle on 17/02/21.
//

import Foundation
import SwiftUI
import AppmarksFramework

struct NewGroupScreen: View {
    
    @Environment(\.managedObjectContext) var context
    
    @Binding var isShowing: Bool
    @Binding var createdGroup: AppmarksFramework.Group?
    
    @State private var name = ""
    
    init(isShowing: Binding<Bool>) {
        self._isShowing = isShowing
        self._createdGroup = .constant(nil)
    }
    
    init(isShowing: Binding<Bool>, createdGroup: Binding<AppmarksFramework.Group?>) {
        self._isShowing = isShowing
        self._createdGroup = createdGroup
    }

    var body: some View {
        NavigationView {
            List {
                Section {
                    TextField("Name", text: $name)
                }
            }
            .listStyle(GroupedListStyle())
            .navigationBarTitle(Text("New Group"), displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: {
                        isShowing = false
                    })
                }
                ToolbarItem {
                    Button("Done", action: {
                        createGroup()
                    })
                }
            }
        }
    }
    
    func createGroup() {
        
        // make sure a name is provided
        if name.isEmpty {
            name = "Unnamed Group"
        }
        
        // create group
        let group = Group(context: context)
        group.id = UUID()
        group.name = name
        
        // save coredata
        try? context.save()
        
        // update binding
        createdGroup = group
        
        // dismiss
        isShowing = false
        
    }
    
}

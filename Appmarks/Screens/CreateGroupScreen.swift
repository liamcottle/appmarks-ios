//
//  CreateGroupScreen.swift
//  Appmarks
//
//  Created by Liam Cottle on 17/02/21.
//

import Foundation
import SwiftUI

struct CreateGroupScreen: View {
    
    @Environment(\.managedObjectContext) var context
    @Environment(\.presentationMode) var presentation
    
    @State private var name = ""
    @Binding var createdGroup: Group?
    
    init(_ createdGroup: Binding<Group?>) {
        self._createdGroup = createdGroup
    }

    init() {
        self._createdGroup = .constant(nil)
    }

    var body: some View {
        List {
            Section {
                TextField("Name", text: $name)
            }
        }
        .listStyle(GroupedListStyle())
        .navigationTitle("Create Group")
        .toolbar {
            ToolbarItem {
                Button("Done", action: {
                    createGroup()
                })
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
        
        // dismiss this screen
        self.presentation.wrappedValue.dismiss()
        
    }
    
}

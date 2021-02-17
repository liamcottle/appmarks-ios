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

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $name)
            }
        }
        .navigationTitle("Create Group")
        .toolbar {
            ToolbarItem {
                Button("Create", action: {
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
        
        // dismiss this screen
        self.presentation.wrappedValue.dismiss()
        
    }
    
}

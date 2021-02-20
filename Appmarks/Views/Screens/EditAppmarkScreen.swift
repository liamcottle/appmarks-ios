//
//  EditAppmarkScreen.swift
//  Appmarks
//
//  Created by Liam Cottle on 19/02/21.
//

import Foundation
import SwiftUI
import SDWebImageSwiftUI
import AppmarksFramework

struct EditAppmarkScreen: View {
    
    @Environment(\.managedObjectContext) var context
    
    @Binding var isShowing: Bool
    @ObservedObject var bookmarkedApp: AppmarksFramework.BookmarkedApp
    
    @FetchRequest(
        entity: AppmarksFramework.Group.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \AppmarksFramework.Group.name, ascending: true),
        ],
        predicate: nil
    ) var groups: FetchedResults<AppmarksFramework.Group>
    
    @State private var group: AppmarksFramework.Group?
    
    @State private var isShowingNewGroupScreen = false
    
    init(isShowing: Binding<Bool>, bookmarkedApp: AppmarksFramework.BookmarkedApp) {
        self._isShowing = isShowing
        self.bookmarkedApp = bookmarkedApp
        self._group = State(initialValue: bookmarkedApp.group)
    }
    
    var body: some View {
        NavigationView {
            List {
                
                Section {
                    
                    // show app info
                    HStack {
                        
                        WebImage(url: URL(string: bookmarkedApp.artworkUrl512 ?? ""))
                            .resizable()
                            .placeholder {
                                Rectangle().foregroundColor(.gray)
                            }
                            .indicator(.activity)
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .frame(width: 65, height: 65, alignment: .center)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray, lineWidth: 0.25)
                            )
                        
                        VStack(alignment: .leading) {
                            Text(bookmarkedApp.trackName ?? "Loading App Info")
                                .font(Font.subheadline.bold())
                            if bookmarkedApp.artistName != nil {
                                Text(bookmarkedApp.artistName ?? "")
                                    .font(Font.subheadline)
                            }
                        }
                        
                    }
                    
                    // choose group
                    Picker(selection: $group, label: Text("Group")) {
                        
                        Text("No Group")
                            .tag(nil as AppmarksFramework.Group?)
                            .foregroundColor(.gray)
                        
                        ForEach(groups) { group in
                            Text(group.name ?? "").tag(group as AppmarksFramework.Group?)
                        }
                        
                    }
                    
                }
                
                Section {
                    Button(action: {
                        self.isShowingNewGroupScreen = true
                    }) {
                        Text("Create Group")
                            .foregroundColor(.blue)
                    }
                }
                
            }
            .sheet(isPresented: $isShowingNewGroupScreen) {
                NewGroupScreen(isShowing: $isShowingNewGroupScreen, createdGroup: $group)
            }
            .listStyle(GroupedListStyle())
            .navigationBarTitle(Text("Edit Appmark"), displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: {
                        isShowing = false
                    })
                }
                ToolbarItem {
                    Button("Done", action: {
                        saveAppmark()
                    })
                }
            }
        }
    }
    
    func saveAppmark() {
        
        // update group
        bookmarkedApp.group = group
        
        // save coredata
        try? context.save()
        
        // dismiss this screen
        isShowing = false
        
    }
    
}

//
//  GroupScreen.swift
//  Appmarks
//
//  Created by Liam Cottle on 17/02/21.
//

import Foundation
import SwiftUI

struct GroupScreen : View {
    
    @ObservedObject var group: Group
    @Environment(\.managedObjectContext) var context
    
    @State private var isShowingEditGroupScreen = false
    
    @ViewBuilder
    var listOrEmptyView: some View {
        if group.bookmarkedApps?.count == 0 {
            emptyView
        } else {
            listView
        }
    }

    var emptyView: some View {
        VStack {
            Image(systemName: "bookmark.fill").imageScale(.large)
            Text("This group is empty").bold()
            Text("Fill it up with some Appmarks").foregroundColor(.gray)
        }
    }

    var listView: some View {
        List {
            ForEach(getBookmarkedApps(), id: \.trackId) { bookmarkedApp in
                BookmarkedAppView(bookmarkedApp: bookmarkedApp)
                    .padding(.vertical, 10)
            }
            .onDelete(perform: self.deleteRow)
        }
        .listStyle(InsetGroupedListStyle())
    }

    var body: some View {
        listOrEmptyView
        .navigationTitle(group.name ?? "Unknown Group")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    self.isShowingEditGroupScreen = true
                }) {
                    Image(systemName: "pencil")
                }.sheet(isPresented: $isShowingEditGroupScreen) {
                    NavigationView {
                        EditGroupScreen(group: group)
                    }
                }
            }
        }
    }
    
    private func getBookmarkedApps() -> [BookmarkedApp] {
        return Array(group.bookmarkedApps as? Set<BookmarkedApp> ?? []).sorted {
            $0.trackName ?? "" < $1.trackName ?? ""
        }
    }
    
    private func deleteRow(at indexSet: IndexSet) {
        for index in indexSet {
            
            // find bookmarked app we swiped to delete
            let bookmarkedApp = getBookmarkedApps()[index]
            
            // remove it from group
            group.removeFromBookmarkedApps(bookmarkedApp)
            
            // remove it from coredata
            context.delete(bookmarkedApp)
            
            // save coredata
            try? context.save()
            
        }
    }
    
}

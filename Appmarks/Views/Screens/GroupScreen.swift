//
//  GroupScreen.swift
//  Appmarks
//
//  Created by Liam Cottle on 17/02/21.
//

import Foundation
import SwiftUI
import AppmarksFramework

struct GroupScreen : View {
    
    @Environment(\.managedObjectContext) var context
    
    @ObservedObject var group: AppmarksFramework.Group
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
            
            Image(systemName: "bookmark")
                .imageScale(.large)
                .padding(.bottom, 5)
            
            Text("This group is empty").bold()
            Text("Share an app from the App Store")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
            
            Button("Open the App Store", action: {
                if let url = URL(string: "itms-apps://itunes.apple.com") {
                    UIApplication.shared.open(url)
                }
            }).padding(.top, 5)
            
        }.padding(.horizontal, 25)
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
                EditButton()
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    self.isShowingEditGroupScreen = true
                }) {
                    Image(systemName: "gear")
                }
            }
        }.sheet(isPresented: $isShowingEditGroupScreen) {
            NavigationView {
                EditGroupScreen(isShowing: $isShowingEditGroupScreen, group: group)
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

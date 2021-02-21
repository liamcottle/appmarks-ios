//
//  GroupView.swift
//  Appmarks
//
//  Created by Liam Cottle on 17/02/21.
//

import Foundation
import SwiftUI
import AppmarksFramework
import MultiModal

struct GroupView: View {
    
    @Environment(\.managedObjectContext) var context
    
    @ObservedObject var group: AppmarksFramework.Group
    @State private var isShowingDeleteGroupSheet = false
    @State private var isShowingDeleteGroupWithAppmarksSheet = false

    var body: some View {
        HStack {
            
            // icon
            ZStack {
                
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(UIColor(hexString: group.colour ?? Constants.themeColour)))
                    .frame(width: 35, height: 35)
                
                Image(systemName: group.icon ?? Constants.defaultGroupIcon)
                    .imageScale(.small)
                    .foregroundColor(.white)
                
            }
            
            // group name
            Text(group.name ?? "")
                .font(Font.subheadline.bold())
            
            Spacer()
            
            // bookmarked apps count in this group
            if let count = group.bookmarkedApps?.count {
                Text("\(count)")
                    .foregroundColor(.gray)
            }
            
        }.multiModal { // using multiModal requires us to pass in env
            $0.actionSheet(isPresented: $isShowingDeleteGroupWithAppmarksSheet) {
                ActionSheet(
                    title: Text(group.name ?? "Unknown Group"),
                    message: Text("This group contains Appmarks, what do you want to do with them?"),
                    buttons: [
                        .destructive(Text("Delete Appmarks")) {
                            
                            // delete all appmarks in this group
                            let bookmarkedApps = Array(group.bookmarkedApps as? Set<BookmarkedApp> ?? [])
                            bookmarkedApps.forEach { (bookmarkedApp) in
                                context.delete(bookmarkedApp)
                            }
                            
                            // delete group
                            context.delete(group)
                            
                            // save coredata
                            try? context.save()
                            
                        },
                        .destructive(Text("Ungroup Appmarks")) {
                            
                            // ungroup all appmarks in this group
                            let bookmarkedApps = Array(group.bookmarkedApps as? Set<BookmarkedApp> ?? [])
                            bookmarkedApps.forEach { (bookmarkedApp) in
                                bookmarkedApp.group = nil
                            }
                            
                            // delete group
                            context.delete(group)
                            
                            // save coredata
                            try? context.save()
                            
                        },
                        .cancel(Text("Cancel"))
                    ]
                )
            }.environment(\.managedObjectContext, context)
            $0.actionSheet(isPresented: $isShowingDeleteGroupSheet) {
                ActionSheet(
                    title: Text(group.name ?? "Unknown Group"),
                    buttons: [
                        .destructive(Text("Delete Group")) {
                            
                            // delete group
                            context.delete(group)
                            
                            // save coredata
                            try? context.save()
                            
                        },
                        .cancel(Text("Cancel"))
                    ]
                )
            }.environment(\.managedObjectContext, context)
        }
        .contextMenu {
            
            Button {
                
                if(group.bookmarkedApps?.count ?? 0 > 0){
                    isShowingDeleteGroupWithAppmarksSheet = true
                } else {
                    isShowingDeleteGroupSheet = true
                }
                
            } label: {
                Label("Delete", systemImage: "trash")
            }
            
        }
    }
}

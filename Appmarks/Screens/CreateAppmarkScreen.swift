//
//  CreateAppmarkScreen.swift
//  Appmarks
//
//  Created by Liam Cottle on 18/02/21.
//

import Foundation
import SwiftUI
import SDWebImageSwiftUI

struct CreateAppmarkScreen: View {
    
    var id: Int64
    
    @Environment(\.managedObjectContext) var context
    @Environment(\.presentationMode) var presentation
    
    @FetchRequest(
        entity: Group.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Group.name, ascending: true),
        ],
        predicate: nil
    ) var groups: FetchedResults<Group>
    
    @State private var appInfo: AppInfo?
    @State private var group: Group?

    var body: some View {
        List {
            
            Section {
                
                // show app info
                HStack {
                    
                    WebImage(url: URL(string: appInfo?.artworkUrl512 ?? ""))
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
                        Text(appInfo?.trackName ?? "Loading App Info")
                            .font(Font.subheadline.bold())
                        if appInfo?.artistName != nil {
                            Text(appInfo?.artistName ?? "")
                                .font(Font.subheadline)
                        }
                    }
                    
                }
                
                // choose group
                Picker(selection: $group, label: Text("Group")) {
                    
                    Text("No Group")
                        .tag(nil as Group?)
                        .foregroundColor(.gray)
                    
                    ForEach(groups) { group in
                        Text(group.name ?? "").tag(group as Group?)
                    }
                    
                }
                
            }
            
            Section {
                NavigationLink(destination: CreateGroupScreen($group)) {
                    Text("Create Group")
                }
            }
            
        }
        .listStyle(GroupedListStyle())
        .onAppear(perform: fetchAppInfo)
        .navigationTitle("Create Appmark")
        .toolbar {
            ToolbarItem {
                Button("Done", action: {
                    createAppmark()
                })
            }
        }
    }
    
    func fetchAppInfo() {
        AppleiTunesAPI.lookupByIds(ids: [String(id)]) { response in
            
            // update state from response
            if(response.results.count > 0){
                if let result = response.results.first {
                    appInfo = result
                    return
                }
            }
            
            // todo handle case where we didn't get app info
            
        } errorCallback: { error in
            // todo handle error
        }
    }
    
    func createAppmark() {
        
        // make sure app info was loaded
        guard let appInfo = appInfo else {
            // todo alert user
            return
        }
        
        // create appmark
        let bookmarkedApp = BookmarkedApp(context: context)
        bookmarkedApp.trackId = appInfo.trackId
        bookmarkedApp.trackName = appInfo.trackName
        bookmarkedApp.trackViewUrl = appInfo.trackViewUrl
        bookmarkedApp.artistName = appInfo.artistName
        bookmarkedApp.artworkUrl512 = appInfo.artworkUrl512
        bookmarkedApp.price = appInfo.price ?? 0
        bookmarkedApp.formattedPrice = appInfo.formattedPrice
        bookmarkedApp.currency = appInfo.currency
        
        // set group
        bookmarkedApp.group = group

        // save coredata
        try? context.save()

        // dismiss this screen
        self.presentation.wrappedValue.dismiss()
        
    }
    
}

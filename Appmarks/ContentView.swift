//
//  ContentView.swift
//  Appmarks
//
//  Created by Liam Cottle on 17/02/21.
//

import CoreData
import SwiftUI
import SwiftUIRefresh

// app icon gradient colours: #102C5B #718EB8
let themeColour = UIColor(rgb: 0x102C5B, alphaVal: 1);
let themeColourLight = UIColor(rgb: 0x718EB8, alphaVal: 1);
let themeTextColour = UIColor(rgb: 0xFFFFFF, alphaVal: 1);

struct ViewButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        return configuration.label
            .padding(.vertical, 5)
            .padding(.horizontal, 20)
            .background(Color(configuration.isPressed ? themeColourLight : themeColour))
            .foregroundColor(Color(themeTextColour))
            .cornerRadius(25)
            .font(Font.body.bold())
    }
}

enum ActiveAlert {
    case About, CopyAppStoreLink
}

struct ContentView: View {
    
    @Environment(\.managedObjectContext) var context
    
    @State private var isLoading = false
    
    @State private var isAlertShowing = false
    @State private var activeAlert: ActiveAlert = .About
    
    @FetchRequest(
        entity: BookmarkedApp.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \BookmarkedApp.trackName, ascending: true),
        ],
        predicate: nil
    ) var bookmarkedApps: FetchedResults<BookmarkedApp>
    
    init() {
        UINavigationBar.appearance().tintColor = themeTextColour
        UINavigationBar.appearance().barTintColor = themeColour
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: themeTextColour]
    }
    
    func showAboutAlert() {
        activeAlert = .About
        isAlertShowing = true
    }
    
    func showCopyAppStoreLinkAlert() {
        activeAlert = .CopyAppStoreLink
        isAlertShowing = true
    }
    
    func isAppBookmarked(id: Int64) -> Bool {
        return bookmarkedApps.contains(where: { (bookmarkedApp) -> Bool in
            return bookmarkedApp.trackId == id;
        });
    }
    
    func findOrCreateBookmarkedApp(id: Int64) -> BookmarkedApp {
        return bookmarkedApps.first(where: { (bookmarkedApp) -> Bool in
            return bookmarkedApp.trackId == id;
        }) ?? BookmarkedApp(context: context)
    }
    
    func getBookmarkedAppIdsAsStrings() -> [String] {
        return bookmarkedApps.map { (bookmarkedApp) -> String in
            return String(bookmarkedApp.trackId)
        }
    }
    
    func addApp(id: Int64) {
        
        // log
        print("addApp: [\(id)]")
        
        AppleiTunesAPI.lookupByIds(ids: [String(id)]) { response in
            
            if(response.results.count > 0){
                
                let result = response.results.first
                
                if(result != nil){
                    updateApp(appInfo: result!)
                }
                
            }
            
            // todo tell user result?
            
        } errorCallback: { error in
            // todo handle error
            print("ERROR:" + (error?.localizedDescription ?? "Unknown Error"))
        }
        
    }
    
    func updateApp(appInfo: AppInfo) {
        
        // log
        print("updateApp: [\(appInfo.trackId)] \(appInfo.trackName)")
        
        // find or create app
        let bookmarkedApp = findOrCreateBookmarkedApp(id: appInfo.trackId)
        
        // update details
        bookmarkedApp.trackId = appInfo.trackId
        bookmarkedApp.trackName = appInfo.trackName
        bookmarkedApp.trackViewUrl = appInfo.trackViewUrl
        bookmarkedApp.artistName = appInfo.artistName
        bookmarkedApp.artworkUrl512 = appInfo.artworkUrl512
        bookmarkedApp.price = appInfo.price ?? 0
        bookmarkedApp.formattedPrice = appInfo.formattedPrice
        bookmarkedApp.currency = appInfo.currency
        
        // save to coredata
        do {
            try context.save()
        } catch {
            print(error)
        }
        
    }
    
    func deleteApp(bookmarkedApp: BookmarkedApp) {
        
        // log
        print("deleteApp: \(bookmarkedApp.trackId)")
        
        // delete bookmarked app
        context.delete(bookmarkedApp)
        
        // save to coredata
        do {
            try context.save()
        } catch {
            print(error)
        }
        
    }
    
    func refreshApps() {
        
        print("refreshApps")
        
        self.isLoading = true
        
        // lookup bookmarked apps
        AppleiTunesAPI.lookupByIds(ids: getBookmarkedAppIdsAsStrings()) { response in
            
            print("refreshApps: response")
            
            // update bookmarked apps in core data
            response.results.forEach { (appInfo) in
                updateApp(appInfo: appInfo)
            }
            
            // no longer loading
            self.isLoading = false
            
        } errorCallback: { error in
            
            print("refreshApps: errorCallback")
            
            // no longer loading
            self.isLoading = false
            
            // todo handle error
            print("refreshApps: error = " + (error?.localizedDescription ?? "Unknown Error"))
            
        }
        
    }
    
    private func deleteRow(at indexSet: IndexSet) {
        for index in indexSet {
            deleteApp(bookmarkedApp: bookmarkedApps[index])
        }
    }
    
    func addAppFromClipboard() {
        
        // add app from app id on clipboard
        if let appId = ClipboardUtil.getAppIdFromClipboard() {
            addApp(id: appId)
            return
        }
        
        // otherwise, show alert asking user to copy link
        showCopyAppStoreLinkAlert()
        
    }
    
    @ViewBuilder
    var bookmarkedAppsView: some View {
        if bookmarkedApps.isEmpty {
            bookmarkedAppsEmptyView
        } else {
            bookmarkedAppsListView
        }
    }

    var bookmarkedAppsEmptyView: some View {
        VStack {
            Image(systemName: "bookmark.fill").imageScale(.large)
            Text("You have no Appmarks").bold()
            Text("Tap the + icon to add your first Appmark").foregroundColor(.gray)
        }
    }

    var bookmarkedAppsListView: some View {
        List {
            ForEach(bookmarkedApps, id: \.trackId) { bookmarkedApp in
                BookmarkedAppView(bookmarkedApp: bookmarkedApp)
                    .padding(.vertical, 10)
            }
            .onDelete(perform: self.deleteRow)
        }
    }

    @ViewBuilder
    var body: some View {
        NavigationView {
            bookmarkedAppsView
            .pullToRefresh(isShowing: $isLoading) {
                refreshApps()
            }
            .onChange(of: isLoading) { value in
                print("isLoading: \(isLoading)")
            }
            .onAppear(perform: refreshApps)
            .navigationBarTitle(Text("Appmarks"), displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showAboutAlert()
                    }) {
                        Image(systemName: "bookmark.fill")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        addAppFromClipboard()
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }.alert(isPresented: $isAlertShowing) {
                switch activeAlert {
                case .About:
                    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
                    return Alert(
                        title: Text("Appmarks v\(appVersion)"),
                        message: Text("Developed by Liam Cottle\nliam@liamcottle.com"),
                        dismissButton: .default(Text("OK"))
                    )
                case .CopyAppStoreLink:
                    return Alert(
                        title: Text("Copy an AppStore Link"),
                        message: Text("To add an Appmark, copy an AppStore link to your clipboard and then try again."),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
        }
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

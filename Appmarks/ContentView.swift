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
    case About, CopyAppStoreLink, InvalidSharedUrl
}

struct ContentView: View {
    
    @Environment(\.managedObjectContext) var context
    @Environment(\.sharedUrl) var sharedUrl
    
    @State private var isLoading = false
    
    @State private var isAlertShowing = false
    @State private var activeAlert: ActiveAlert = .About
    
    @State private var isShowingCreateGroupScreen = false
    
    @State private var isShowingCreateAppmarkScreen = false
    @State private var createAppmarkScreenAppId: Int64 = 0
    
    // get list of all bookmarked apps so they can be refreshed
    @FetchRequest(
        entity: BookmarkedApp.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \BookmarkedApp.trackName, ascending: true),
        ],
        predicate: nil
    ) var bookmarkedApps: FetchedResults<BookmarkedApp>
    
    // get list of ungrouped bookmarked apps to show on main screen
    @FetchRequest(
        entity: BookmarkedApp.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \BookmarkedApp.trackName, ascending: true),
        ],
        predicate: NSPredicate(format: "group == null")
    ) var ungroupedBookmarkedApps: FetchedResults<BookmarkedApp>
    
    // get list of groups to show on main screen
    @FetchRequest(
        entity: Group.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Group.name, ascending: true),
        ],
        predicate: nil
    ) var groups: FetchedResults<Group>
    
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
    
    func showInvalidSharedUrlAlert() {
        activeAlert = .InvalidSharedUrl
        isAlertShowing = true
    }
    
    func showCreateAppmarkScreen(appId: Int64) {
        createAppmarkScreenAppId = appId
        isShowingCreateAppmarkScreen = true
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
        
        // show screen to create appmark
        showCreateAppmarkScreen(appId: id)
        
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
    
    func deleteBookmarkedApp(bookmarkedApp: BookmarkedApp) {
        
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
    
    func deleteGroup(group: Group) {
        
        // log
        print("deleteGroup: \(group.name ?? "")")
        
        // delete group
        context.delete(group)
        
        // save to coredata
        do {
            try context.save()
        } catch {
            print(error)
        }
        
    }
    
    func refreshBookmarkedApps() {
        
        print("refreshBookmarkedApps")
        
        self.isLoading = true
        
        // lookup bookmarked apps
        AppleiTunesAPI.lookupByIds(ids: getBookmarkedAppIdsAsStrings()) { response in
            
            print("refreshBookmarkedApps: response")
            
            // update bookmarked apps in core data
            response.results.forEach { (appInfo) in
                updateApp(appInfo: appInfo)
            }
            
            // no longer loading
            self.isLoading = false
            
        } errorCallback: { error in
            
            print("refreshBookmarkedApps: errorCallback")
            
            // no longer loading
            self.isLoading = false
            
            // todo handle error
            print("refreshBookmarkedApps: error = " + (error?.localizedDescription ?? "Unknown Error"))
            
        }
        
    }
    
    private func deleteBookmarkedAppRow(at indexSet: IndexSet) {
        for index in indexSet {
            deleteBookmarkedApp(bookmarkedApp: ungroupedBookmarkedApps[index])
        }
    }
    
    private func deleteGroupRow(at indexSet: IndexSet) {
        for index in indexSet {
            deleteGroup(group: groups[index])
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
    
    func addAppFromSharedUrl(sharedUrl: String) {
        
        // add app from app id found in shared url
        if let appId = AppIdUtil.findAppIdInString(string: sharedUrl) {
            if let id = Int64(appId) {
                addApp(id: id)
                return
            }
        }
        
        // otherwise, show alert telling user url is invalid
        showInvalidSharedUrlAlert()
        
    }
    
    @ViewBuilder
    var listOrEmptyView: some View {
        if ungroupedBookmarkedApps.isEmpty && groups.isEmpty {
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
            
            Text("You have no Appmarks").bold()
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
            
            // section of groups
            if !groups.isEmpty {
                Section {
                    ForEach(groups, id: \.id) { (group: Group) in
                        NavigationLink(destination: GroupScreen(group: group)) {
                            GroupView(group: group)
                                .padding(.vertical, 10)
                        }
                    }
                    .onDelete(perform: self.deleteGroupRow)
                }
            }
            
            // section of bookmarked apps
            if !ungroupedBookmarkedApps.isEmpty {
                Section {
                    ForEach(ungroupedBookmarkedApps, id: \.trackId) { bookmarkedApp in
                        BookmarkedAppView(bookmarkedApp: bookmarkedApp)
                            .padding(.vertical, 10)
                    }
                    .onDelete(perform: self.deleteBookmarkedAppRow)
                }
            }
            
        }
        .listStyle(InsetGroupedListStyle())
    }

    @ViewBuilder
    var body: some View {
        NavigationView {
            HStack {
                listOrEmptyView
            }
            .pullToRefresh(isShowing: $isLoading) {
                refreshBookmarkedApps()
            }
            .onChange(of: isLoading) { value in
                print("isLoading: \(isLoading)")
            }
            .onChange(of: sharedUrl, perform: { sharedUrl in
                
                // handle shared url
                if let sharedUrl = sharedUrl {
                    addAppFromSharedUrl(sharedUrl: sharedUrl)
                }
                
            })
            .background(
                NavigationLink("", destination: CreateAppmarkScreen(id: createAppmarkScreenAppId), isActive: $isShowingCreateAppmarkScreen)
                    .isDetailLink(false)
            )
            .background(
                NavigationLink("", destination: CreateGroupScreen(), isActive: $isShowingCreateGroupScreen)
                    .isDetailLink(false)
            )
            .onAppear(perform: refreshBookmarkedApps)
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        self.isShowingCreateGroupScreen = true
                    }) {
                        Image(systemName: "folder.badge.plus")
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
                case .InvalidSharedUrl:
                    return Alert(
                        title: Text("Invalid AppStore Link"),
                        message: Text("The link you shared doesn't appear to be a valid AppStore URL."),
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

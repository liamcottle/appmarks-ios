//
//  ContentView.swift
//  Appmarks
//
//  Created by Liam Cottle on 17/02/21.
//

import CoreData
import SwiftUI
import SwiftUIRefresh
import MultiModal
import AppmarksFramework

let themeColour = UIColor(hexString: Constants.themeColour);
let themeColourLight = UIColor(hexString: Constants.themeColourLight);
let themeTextColour = UIColor(hexString: Constants.themeTextColour);

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
    
    @ObservedObject var userSettings = UserSettings()
    
    @State private var isLoading = false
    
    @State private var isAlertShowing = false
    @State private var activeAlert: ActiveAlert = .About
    
    @State private var isShowingWelcomeScreen = false
    @State private var isShowingNewGroupScreen = false
    
    @State private var isShowingNewAppmarkScreen = false
    @State private var createAppmarkScreenAppId: Int64 = 0
    
    // get list of all bookmarked apps so they can be refreshed
    @FetchRequest(
        entity: AppmarksFramework.BookmarkedApp.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \AppmarksFramework.BookmarkedApp.trackName, ascending: true),
        ],
        predicate: nil
    ) var bookmarkedApps: FetchedResults<AppmarksFramework.BookmarkedApp>
    
    // get list of ungrouped bookmarked apps to show on main screen
    @FetchRequest(
        entity: AppmarksFramework.BookmarkedApp.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \AppmarksFramework.BookmarkedApp.trackName, ascending: true),
        ],
        predicate: NSPredicate(format: "group == null")
    ) var ungroupedBookmarkedApps: FetchedResults<AppmarksFramework.BookmarkedApp>
    
    // get list of groups to show on main screen
    @FetchRequest(
        entity: AppmarksFramework.Group.entity(),
        sortDescriptors: [
            NSSortDescriptor(
                keyPath: \AppmarksFramework.Group.order,
               ascending: true),
            NSSortDescriptor(keyPath: \AppmarksFramework.Group.name, ascending: true),
        ],
        predicate: nil
    ) var groups: FetchedResults<AppmarksFramework.Group>
    
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
        isShowingNewAppmarkScreen = true
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
        
        // // close existing create screen
        isShowingNewAppmarkScreen = false
        
        // show screen to create appmark after closing previous (must use dispatch queue 🤷‍♂️)
        DispatchQueue.main.async {
            showCreateAppmarkScreen(appId: id)
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
    
    func deleteGroup(group: AppmarksFramework.Group) {
        
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
    
    func onDidAppear() {
        
        // automatically merge remote changes into coredata
        CoreDataStack.sharedInstance.initRemoteChangeObserver()
        
        // refresh bookmarked app info
        refreshBookmarkedApps()
        
        // show welcome screen if user hasn't seen it
        if(!userSettings.hasSeenWelcomeScreen){
            isShowingWelcomeScreen = true
            userSettings.hasSeenWelcomeScreen = true
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
    
    private func moveGroupRow(from source: IndexSet, to before: Int) {
        
        let firstIndex = source.min()!
        let lastIndex = source.max()!
        
        let firstRowToReorder = (firstIndex < before) ? firstIndex : before
        let lastRowToReorder = (lastIndex > (before-1)) ? lastIndex : (before-1)
        
        if firstRowToReorder != lastRowToReorder {
            
            var newOrder = firstRowToReorder
            if newOrder < firstIndex {
                // Moving dragged items up, so re-order dragged items first
                
                // Re-order dragged items
                for index in source {
                    groups[index].setValue(newOrder, forKey: "order")
                    newOrder = newOrder + 1
                }
                
                // Re-order non-dragged items
                for rowToMove in firstRowToReorder..<lastRowToReorder {
                    if !source.contains(rowToMove) {
                        groups[rowToMove].setValue(newOrder, forKey: "order")
                        newOrder = newOrder + 1
                    }
                }
            } else {
                // Moving dragged items down, so re-order dragged items last
                
                // Re-order non-dragged items
                for rowToMove in firstRowToReorder...lastRowToReorder {
                    if !source.contains(rowToMove) {
                        groups[rowToMove].setValue(newOrder, forKey: "order")
                        newOrder = newOrder + 1
                    }
                }
                
                // Re-order dragged items
                for index in source {
                    groups[index].setValue(newOrder, forKey: "order")
                    newOrder = newOrder + 1
                }
            }
            
        }
        
        // save to coredata
        try? context.save()
        
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
                    ForEach(groups, id: \.id) { (group: AppmarksFramework.Group) in
                        NavigationLink(destination: GroupScreen(group: group)) {
                            GroupView(group: group)
                                .padding(.vertical, 10)
                        }
                    }
                    .onDelete(perform: self.deleteGroupRow)
                    .onMove(perform: self.moveGroupRow)
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
            .multiModal { // using multiModal requires us to pass in env
                $0.sheet(isPresented: $isShowingWelcomeScreen) {
                    WelcomeScreen(isShowing: $isShowingWelcomeScreen)
                }
                $0.sheet(isPresented: $isShowingNewAppmarkScreen) {
                    NewAppmarkScreen(id: $createAppmarkScreenAppId, isShowing: $isShowingNewAppmarkScreen)
                        .environment(\.managedObjectContext, context)
                }
                $0.sheet(isPresented: $isShowingNewGroupScreen) {
                    NewGroupScreen(isShowing: $isShowingNewGroupScreen)
                        .environment(\.managedObjectContext, context)
                }
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
            .onAppear(perform: onDidAppear)
            .navigationBarTitle(Text("Appmarks"), displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showAboutAlert()
                    }) {
                        Image(systemName: "bookmark.fill")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        addAppFromClipboard()
                    }) {
                        Image(systemName: "paperclip")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isShowingNewGroupScreen = true
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
        }.navigationViewStyle(StackNavigationViewStyle())
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

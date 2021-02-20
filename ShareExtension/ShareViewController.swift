//
//  ShareViewController.swift
//  ShareExtension
//
//  Created by Liam Cottle on 17/02/21.
//

import UIKit
import Social
import CoreServices
import AppmarksFramework
import SDWebImageSwiftUI
import SwiftUI

struct NewAppmarkScreen: View {
    
    @Environment(\.managedObjectContext) var context
    @Environment(\.extensionContext) var extensionContext
    
    @FetchRequest(
        entity: AppmarksFramework.Group.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \AppmarksFramework.Group.name, ascending: true),
        ],
        predicate: nil
    ) var groups: FetchedResults<AppmarksFramework.Group>
    
    @State private var isValidShare = true
    @State private var isErrorLoading = false
    @State private var appInfo: AppInfo?
    @State private var group: AppmarksFramework.Group?
    
    @State private var isShowingNewGroupScreen = false
    
    func findURLAttachment() -> NSItemProvider? {
        
        if let item = extensionContext?.inputItems.first as? NSExtensionItem {
            if let attachments = item.attachments {
                for attachment in attachments {
                    if(attachment.hasItemConformingToTypeIdentifier(kUTTypeURL as String)){
                        return attachment
                    }
                }
            }
        }
        
        return nil
        
    }
    
    var body: some View {
        NavigationView {
            List {
                
                if isErrorLoading {
                    Section {
                        Text("Something went wrong loading the App Info.")
                    }
                } else if isValidShare {
                    
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
                            Text("New Group")
                                .foregroundColor(.blue)
                        }
                    }
                    
                } else {
                    Section {
                        Text("The link you shared doesn't appear to be a valid App Store URL.")
                    }
                }
                
            }
            .sheet(isPresented: $isShowingNewGroupScreen) {
                NewGroupScreen(isShowing: $isShowingNewGroupScreen, createdGroup: $group)
            }
            .listStyle(GroupedListStyle())
            .onAppear(perform: onDidAppear)
            .navigationBarTitle(Text("New Appmark"), displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: {
                        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
                    })
                }
                ToolbarItem {
                    if(isValidShare && !isErrorLoading){
                        Button("Done", action: {
                            createAppmark()
                        })
                    } else {
                        Button("Close", action: {
                            extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
                        })
                    }
                }
            }
        }
    }
    
    func onDidAppear() {
        
        // make sure we have a valid url attachment
        guard let urlAttachment = findURLAttachment() else {
            isValidShare = false
            return
        }
        
        // load url from attachment
        urlAttachment.loadItem(forTypeIdentifier: kUTTypeURL as String, options: nil) { (data, error) in
            
            // check for error
            if(error != nil){
                isValidShare = false
                return
            }
            
            // parse app id from url
            if let sharedURL = data as? URL {
                if let appIdString = AppIdUtil.findAppIdInString(string: sharedURL.absoluteString) {
                    if let appId = Int64(appIdString) {
                        fetchAppInfo(appId: appId)
                        return
                    }
                }
            }
            
            // didn't find app id
            isValidShare = false
            
        }
        
    }
    
    func fetchAppInfo(appId: Int64) {
        
        // don't fetch app info if we already fetched it
        if appInfo != nil {
            return
        }
        
        AppleiTunesAPI.lookupByIds(ids: [String(appId)]) { response in
            
            // update state from response
            if(response.results.count > 0){
                if let result = response.results.first {
                    appInfo = result
                    return
                }
            }
            
            // handle case where we didn't get app info
            isErrorLoading = true
            
        } errorCallback: { error in
            // handle error
            isErrorLoading = true
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

        // dismiss extension
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        
    }
    
}

struct ExtensionContextKey: EnvironmentKey {
    static var defaultValue: NSExtensionContext? {
        return nil
    }
}

extension EnvironmentValues {
    var extensionContext: NSExtensionContext? {
        get {
            self[ExtensionContextKey]
        }
        set {
            self[ExtensionContextKey] = newValue
        }
    }
}

class ShareViewController: UIViewController {
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let context = CoreDataStack.sharedInstance.persistentContainer.viewContext
        
        // create swiftui hosting controller
        let viewController = UIHostingController(rootView: AnyView(
            NewAppmarkScreen()
                .environment(\.managedObjectContext, context)
                .environment(\.extensionContext, extensionContext)
        ))
        
        // add hosting controller to view
        self.addChild(viewController)
        self.view.addSubview(viewController.view)
        viewController.didMove(toParent: self)
        view.addSubview(viewController.view)

        // setup constraints
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        viewController.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        viewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        viewController.view.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        viewController.view.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        
    }
    
}

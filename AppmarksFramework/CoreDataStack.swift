//
//  CoreDataStack.swift
//  AppmarksFramework
//
//  Created by Liam Cottle on 19/02/21.
//

import Foundation
import CoreData
import UIKit

public extension URL {

    // Returns a URL for the given app group and database pointing to the sqlite database.
    static func storeURL(for appGroup: String, databaseName: String) -> URL {
        guard let fileContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) else {
            fatalError("Shared file container could not be created.")
        }

        return fileContainer.appendingPathComponent("\(databaseName).sqlite")
    }
}

/// subclass of NSPersistentContainer is used so it automatically finds the correct data model
public class PersistentContainer: NSPersistentContainer {}

public class CoreDataStack {
    
    public static let sharedInstance = CoreDataStack()
    
    private var historyTimestamp: Date = Date.init()
    public var persistentContainer: NSPersistentContainer = {
        
        // create persistent container from xcdatamodeld file
        let container = PersistentContainer(name: "AppmarksDataModel")
        
        // save coredata in app group so it can be accessed by mainapp and share extension
        let storeURL = URL.storeURL(for: "group.com.liamcottle.ios.Appmarks", databaseName: "Appmarks")
        let storeDescription = NSPersistentStoreDescription(url: storeURL)
        
        // we want to track history and merge it in when a remote change notification is received
        storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        container.persistentStoreDescriptions = [storeDescription]
        
        // set current process bundle id as the transaction author
        container.viewContext.transactionAuthor = Bundle.main.bundleIdentifier
        
        // load the stores
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error {
                fatalError("Unresolved error \(error), \(error)")
            }
        })
        
        return container
        
    }()
    
    // this should be called by the main app when it starts
    public func initRemoteChangeObserver() {
        NotificationCenter.default.addObserver(self,
            selector: #selector(processRemoteStoreChange),
                name: .NSPersistentStoreRemoteChange,
                object: CoreDataStack.sharedInstance.persistentContainer.persistentStoreCoordinator)
    }
    
    @objc func processRemoteStoreChange(_ notification: Notification) {
        DispatchQueue(label: "history").async { [weak self] in
            
            // make sure we have a reference to self
            guard let self = self else { return }
            
            // run on background context
            let backgroundContext = self.persistentContainer.newBackgroundContext()
            backgroundContext.performAndWait { [weak self] in
                
                // make sure we have a reference to self
                guard let self = self else { return }

                // request to fetch history after last merged history timestamp
                let request = NSPersistentHistoryChangeRequest.fetchHistory(after: self.historyTimestamp)

                // get history that wasn't authored by main app (ie, only history authored by share extension)
                if let historyFetchRequest = NSPersistentHistoryTransaction.fetchRequest {
                    historyFetchRequest.predicate = NSPredicate(format: "author != %@", "com.liamcottle.ios.Appmarks")
                    request.fetchRequest = historyFetchRequest
                }

                // execute history fetch and make sure transactions are not empty
                guard let result = try? backgroundContext.execute(request) as? NSPersistentHistoryResult,
                      let transactions = result.result as? [NSPersistentHistoryTransaction],
                      transactions.isEmpty == false else {
                    return
                }

                // merge in the changes from transactions
                self.persistentContainer.viewContext.perform {
                    transactions.forEach { [weak self] transaction in
                        guard let self = self, let userInfo = transaction.objectIDNotification().userInfo else { return }
                        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: userInfo, into: [self.persistentContainer.viewContext])
                    }
                }

                // update history timestamp from last transaction
                if let timestamp = transactions.last?.timestamp {
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.historyTimestamp = timestamp
                    }
                }
            }
            
        }
    }
    
}

//
//  ShareViewController.swift
//  ShareExtension
//
//  Created by Liam Cottle on 17/02/21.
//

import UIKit
import Social
import CoreServices

class ShareViewController: UIViewController {
    
    // allow using openURL inside of share extension
    @objc func openURL(_ url: URL) -> Bool {
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                return application.perform(#selector(openURL(_:)), with: url) != nil
            }
            responder = responder?.next
        }
        return false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        // find shared url and send to main app
        var launchedSharedUrl = false
        if let item = extensionContext?.inputItems.first as? NSExtensionItem {
            if let attachments = item.attachments {
                attachments.forEach { (attachment) in
                    if(!launchedSharedUrl){
                        if(attachment.hasItemConformingToTypeIdentifier(kUTTypeURL as String)){
                            attachment.loadItem(forTypeIdentifier: kUTTypeURL as String, options: nil) { (data, error) in
                                if let sharedURL = data as? URL {
                                    launchedSharedUrl = true
                                    self.launchAppWithSharedUrl(sharedUrl: sharedURL.absoluteString)
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // finish share extension
        self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        
    }
    
    func launchAppWithSharedUrl(sharedUrl: String) {
        if let url = URL(string: "appmarks://?url=\(sharedUrl)") {
            openURL(url)
        }
    }
}

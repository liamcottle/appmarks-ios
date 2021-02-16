//
//  AppleiTunesAPI.swift
//  Appmarks
//
//  Created by Liam Cottle on 17/02/21.
//

import Foundation

struct AppLookupResponse: Codable {
    var results: [AppInfo]
}

struct AppInfo: Codable {
    var trackId: Int64
    var trackName: String
    var kind: String
    var artistName: String
    var price: Double?
    var artworkUrl512: String
    var trackViewUrl: String
    var formattedPrice: String?
    var currency: String
}

class AppleiTunesAPI {
    
    static func lookupByIds(ids: [String], successCallback: @escaping (AppLookupResponse)->(), errorCallback: @escaping (Error?)->()) {
        
        // generate lookup url
        guard let url = URL(string: "http://itunes.apple.com/lookup?id=" + ids.joined(separator: ",")) else {
            errorCallback(NSError(domain: "Invalid URL", code: 0, userInfo: nil))
            return;
        }
        
        // disable local cache
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        
        // make request
        URLSession.init(configuration: config).dataTask(with: URLRequest(url: url)) { data, response, error in
            
            // check for error
            if(error != nil){
                DispatchQueue.main.async {
                    errorCallback(error)
                }
                return
            }
            
            // check if data is nil
            if(data == nil){
                DispatchQueue.main.async {
                    errorCallback(NSError(domain: "Data is nil", code: 0, userInfo: nil))
                }
                return
            }
            
            // decode and return results
            do {
                let appLookupResponse = try JSONDecoder().decode(AppLookupResponse.self, from: data!)
                DispatchQueue.main.async {
                    successCallback(appLookupResponse)
                }
            } catch let error as NSError {
                DispatchQueue.main.async {
                    errorCallback(error)
                }
            }
            
        }.resume()
        
    }
    
}

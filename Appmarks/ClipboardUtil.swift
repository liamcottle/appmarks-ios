//
//  ClipboardUtil.swift
//  Appmarks
//
//  Created by Liam Cottle on 17/02/21.
//

import Foundation
import SwiftUI

class ClipboardUtil {
    
    static func getAppIdFromClipboard() -> Int64? {
        if let text = UIPasteboard.general.string {
            if let appId = findAppIdFromText(text: text) {
                if let id = Int64(appId) {
                    return id
                }
            }
        }
        return nil
    }
    
    private static func matches(for regex: String, in text: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            return results.map {
                String(text[Range($0.range, in: text)!])
            }
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
    
    private static func findAppIdFromText(text: String) -> String? {
        let matched = matches(for: "/id([0-9]+)", in: text)
        if(matched.count > 0){
            return matched[0].replacingOccurrences(of: "/id", with: "")
        }
        return nil
    }
    
}

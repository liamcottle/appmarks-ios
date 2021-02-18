//
//  AppIdUtil.swift
//  Appmarks
//
//  Created by Liam Cottle on 17/02/21.
//

import Foundation

public class AppIdUtil {
    
    public static func findAppIdInString(string: String) -> String? {
        let matched = matches(for: "/id([0-9]+)", in: string)
        if(matched.count > 0){
            return matched[0].replacingOccurrences(of: "/id", with: "")
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
    
}

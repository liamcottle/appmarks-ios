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
            if let appId = AppIdUtil.findAppIdInString(string: text) {
                if let id = Int64(appId) {
                    return id
                }
            }
        }
        return nil
    }
    
}

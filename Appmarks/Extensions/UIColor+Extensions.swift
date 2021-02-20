//
//  UIColor+Extensions.swift.swift
//  Appmarks
//
//  Created by Liam Cottle on 17/02/21.
//

import Foundation
import SwiftUI

extension UIColor{
    convenience init(rgb: UInt, alphaVal: CGFloat) {
        self.init(
            red: CGFloat((rgb & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgb & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgb & 0x0000FF) / 255.0,
            alpha: alphaVal
        )
    }
}

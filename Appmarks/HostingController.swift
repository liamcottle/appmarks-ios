//
//  HostingController.swift
//  Appmarks
//
//  Created by Liam Cottle on 17/02/21.
//

import Foundation
import SwiftUI

class HostingController<ContentView>: UIHostingController<ContentView> where ContentView : View {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

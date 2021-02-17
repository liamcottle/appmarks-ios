//
//  GroupView.swift
//  Appmarks
//
//  Created by Liam Cottle on 17/02/21.
//

import Foundation
import SwiftUI

struct GroupView: View {
    
    @ObservedObject var group: Group

    var body: some View {
        HStack {
            
            // icon
            Image(systemName: "folder")
                .imageScale(.large)
            
            // group name
            Text(group.name ?? "")
                .font(Font.subheadline.bold())
            
            Spacer()
            
            // bookmarked apps count in this group
            if let count = group.bookmarkedApps?.count {
                Text("\(count)")
                    .foregroundColor(.gray)
            }
            
        }
    }
}

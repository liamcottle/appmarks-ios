//
//  BookmarkedAppView.swift
//  Appmarks
//
//  Created by Liam Cottle on 17/02/21.
//

import Foundation
import SwiftUI
import SDWebImageSwiftUI
import AppmarksFramework

struct BookmarkedAppView: View {
    
    @Environment(\.managedObjectContext) var context
    
    var bookmarkedApp: AppmarksFramework.BookmarkedApp

    var body: some View {
        HStack {
            
            WebImage(url: URL(string: bookmarkedApp.artworkUrl512 ?? ""))
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
                Text(bookmarkedApp.trackName ?? "")
                    .font(Font.subheadline.bold())
                Text(bookmarkedApp.artistName ?? "")
                    .font(Font.subheadline)
            }
            
            Spacer()
            
            VStack {
                
                // only show price if available
                if(bookmarkedApp.formattedPrice != nil){
                    let currency = bookmarkedApp.currency ?? ""
                    let formattedPrice = bookmarkedApp.formattedPrice ?? ""
                    let text = bookmarkedApp.price == 0 ? formattedPrice : "\(currency) \(formattedPrice)"
                    Text(text)
                        .font(Font.caption.bold())
                }
                
                Button(action: {
                    if let url = URL(string: bookmarkedApp.trackViewUrl ?? "") {
                        UIApplication.shared.open(url)
                    }
                }, label: {
                    Text("VIEW")
                })
                .frame(height: 30, alignment: .center)
                .buttonStyle(ViewButtonStyle())
                
            }
            
        }.contextMenu {
            
            Button {
                
                // delete bookmarked app
                context.delete(bookmarkedApp)
                
                // save coredata
                try? context.save()
                
            } label: {
                Label("Delete", systemImage: "trash")
            }
            
            if bookmarkedApp.group != nil {
                
                Button {
                    
                    // remove bookmarked app from group
                    bookmarkedApp.group = nil
                    
                    // save coredata
                    try? context.save()
                    
                } label: {
                    Label("Remove from Group", systemImage: "folder.badge.minus")
                }
                
            }
            
        }
    }
}

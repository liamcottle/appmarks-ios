//
//  IconPickerView.swift
//  AppmarksFramework
//
//  Created by Liam Cottle on 21/02/21.
//

import Foundation
import SwiftUI

public struct IconPickerView: View {

    @Binding var colour: String?
    @Binding var selection: String?
    
    var icons: [String] = Constants.groupIcons
    
    public init(selection: Binding<String?>, colour: Binding<String?>) {

        self._selection = selection
        self._colour = colour

        // make sure selection exists in options
        if let selected = self.selection {
            if(!icons.contains(selected)){
                icons.insert(selected, at: 0)
            }
        }

    }
    
    var selectedIconColour: Color {
        if let colour = colour {
            return Color(UIColor(hexString: colour))
        }
        return Color(.gray)
    }
    
    var unselectedIconColour: Color {
        return Color(UIColor.lightGray)
    }

    public var body: some View {

        let columns = [
            GridItem(.adaptive(minimum: 50))
        ]

        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(icons, id: \.self){ icon in
                let iconColour = selection == icon ? selectedIconColour : unselectedIconColour
                ZStack {
                    
                    RoundedRectangle(cornerRadius: 10)
                        .fill(iconColour)
                        .frame(width: 40, height: 40)
                        .onTapGesture(perform: {
                            
                            // update selection
                            selection = icon
                            
                            // perform haptic
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            
                        })
                        .padding(10)
                    
                    Image(systemName: icon)
                        .imageScale(.medium)
                        .foregroundColor(.white)

                    if selection == icon {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(UIColor.lightGray), lineWidth: 3)
                            .frame(width: 50, height: 50)
                    }
                    
                }
            }
        }
        .padding(10)
        
    }
}

struct IconPickerView_Previews: PreviewProvider {
    static var previews: some View {
        IconPickerView(selection: .constant("folder"), colour: .constant("#102C5B"))
    }
}

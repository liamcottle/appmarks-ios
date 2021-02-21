//
//  ColourPickerView.swift
//  Appmarks
//
//  Created by Liam Cottle on 21/02/21.
//

import Foundation
import SwiftUI

public struct ColourPickerView: View {

    @Binding var selection: String?
    
    var colours: [String] = Constants.groupColours
    
    public init(selection: Binding<String?>) {

        self._selection = selection

        // make sure selection exists in options
        if let selected = self.selection {
            if(!colours.contains(selected)){
                colours.insert(selected, at: 0)
            }
        }

    }

    public var body: some View {

        let columns = [
            GridItem(.adaptive(minimum: 50))
        ]

        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(colours, id: \.self){ colour in
                ZStack {
                    Circle()
                        .fill(Color(UIColor(hexString: colour)))
                        .frame(width: 40, height: 40)
                        .onTapGesture(perform: {
                            
                            // update selection
                            selection = colour
                            
                            // perform haptic
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            
                        })
                        .padding(10)

                    if selection == colour {
                        Circle()
                            .stroke(Color(UIColor(hexString: colour)), lineWidth: 3)
                            .frame(width: 50, height: 50)
                    }
                }
            }
        }
        .padding(10)
        
    }
}

struct ColourPickerView_Previews: PreviewProvider {
    static var previews: some View {
        ColourPickerView(selection: .constant("#102C5B"))
    }
}

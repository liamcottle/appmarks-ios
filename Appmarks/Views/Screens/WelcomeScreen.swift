//
//  WelcomeScreen.swift
//  Appmarks
//
//  Created by Liam Cottle on 21/02/21.
//

import Foundation
import SwiftUI
import AppmarksFramework

struct TitleView: View {
    var body: some View {
        VStack {
            
            Image(uiImage: UIImage(named: "AppmarksLogo") ?? UIImage())
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 125, alignment: .center)
                .accessibility(hidden: true)

            Text("Welcome to")
                .customTitleText()

            Text("Appmarks")
                .customTitleText()
                .foregroundColor(.mainColor)
            
        }.padding(.vertical, 30)
    }
}

struct InformationDetailView: View {
    
    var title: String
    var subTitle: String
    var imageName: String

    var body: some View {
        HStack(alignment: .center) {
            
            Image(systemName: imageName)
                .font(.largeTitle)
                .foregroundColor(.mainColor)
                .frame(width: 30, height: 30)
                .accessibility(hidden: true)
                .padding(.trailing, 15)
            
            VStack(alignment: .leading) {
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .accessibility(addTraits: .isHeader)

                Text(subTitle)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
            }
            
        }
        .padding(.top)
        .padding(.horizontal, 25)
    }
    
}

struct InformationContainerView: View {
    var body: some View {
        VStack(alignment: .leading) {
            
            InformationDetailView(title: "What are Appmarks?", subTitle: "Appmarks are bookmarks to your favourite Apps and Games on the App Store.", imageName: "bookmark")
            
            InformationDetailView(title: "Share from the App Store", subTitle: "Create an Appmark by sharing an app from the App Store.", imageName: "square.and.arrow.up")

            InformationDetailView(title: "Organise Appmarks", subTitle: "Organise your Appmarks into Groups with custom icons and colours.", imageName: "folder")
            
            InformationDetailView(title: "Sync with iCloud", subTitle: "Automatically syncs with iCloud to keep your Appmarks backed up and available on other devices.", imageName: "icloud")
            
        }
        .padding(.horizontal, 0)
    }
}

struct ButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundColor(.white)
            .font(.headline)
            .padding()
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
            .background(RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(Color.mainColor))
            .padding(.bottom)
    }
}

extension View {
    func customButton() -> ModifiedContent<Self, ButtonModifier> {
        return modifier(ButtonModifier())
    }
}

extension Text {
    func customTitleText() -> Text {
        self
            .fontWeight(.black)
            .font(.system(size: 36))
    }
}

extension Color {
    static var mainColor = Color(UIColor(hexString: Constants.themeColour))
}

struct WelcomeScreen: View {
    
    @Binding var isShowing: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center) {

                Spacer()

                TitleView()

                InformationContainerView()

                Spacer(minLength: 30)

                Button(action: {
                    
                    // success haptic
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    
                    // dimiss
                    isShowing = false
                    
                }) {
                    Text("Continue")
                        .customButton()
                }
                .padding(.horizontal)
            }
        }
    }
    
}

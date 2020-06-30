//
//  AppView.swift
//  R1 Preferences
//
//  Created by Andrew Finke on 5/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import SwiftUI
import R1Kit

struct AppView: View {
    
    @EnvironmentObject var app: R1App
    
    var body: some View {
        R1Notifier.local.selected(app: app.name)
        return VStack {
            LeftText(
                text: app.name,
                font: Font.system(size: 17, weight: .semibold, design: .rounded)
            )
            Divider()
            HStack {
                VStack {
                    ColorCollectionHeaderView(text: "Resting")
                    R1BodyView(
                        buttons: Binding(
                            get: { self.app.buttons },
                            set: { self.app.buttons = $0 }),
                        state: .resting
                    )
                }
                Spacer(minLength: 35)
                VStack {
                    ColorCollectionHeaderView(text: "Pressed")
                    R1BodyView(
                        buttons: Binding(
                            get: { self.app.buttons },
                            set: { self.app.buttons = $0 }),
                        state: .pressed
                    )
                }
            }
            .padding(.top, 5)
            .padding(.bottom, 13)
            
            Divider()
            
            LeftText(
                text: "Actions",
                font: Font.system(size: 15, weight: .medium, design: .rounded)
            )
                .padding(.top, 5)
            
            HStack {
                ForEach(app.buttons.indices, id: \.self){ index in
                    HStack {
                        ScriptSelection(
                            button: Binding(
                                get: { self.app.buttons[index] },
                                set: { self.app.buttons[index] = $0 }),
                            title: self.app.buttons[index].id.description
                        )
                        if index != RXHardware.numberOfButtons - 1 {
                            Spacer()
                        }
                    }
                }
            }
            Spacer()
        }
        .padding([.leading, .trailing], 30)
        .padding(.top, 20)
        
    }
}

struct ContentView: View {
    @State var preferences = R1Preferences(rxButtons: RXHardware.numberOfButtons)
    
    var body: some View {
        return NavigationView {
            MasterListView()
                .environmentObject(preferences)
                .frame(width: 160)
            Text("Select an App")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 620, height: 260)
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
        //.environmentObject(UserData())
    }
}

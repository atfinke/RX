//
//  R1AppConfigurationView.swift
//  RX Preferences
//
//  Created by Andrew Finke on 5/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import SwiftUI
import RXKit

struct R1AppConfigurationView: View {
    
    // MARK: - Properties -
    
    @EnvironmentObject var app: RXApp
    @EnvironmentObject var preferences: RXPreferences
    
    // MARK: - Body -
    
    var body: some View {
        RXNotifier.local.selected(app: app)
        return VStack {
            if !(self.preferences.customApps + self.preferences.defaultApps).contains(app) {
                Text("Select an App")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                LeftText(
                    text: self.app.name,
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
                
                actionsView
                Spacer()
            }
        }
        .padding([.leading, .trailing], 30)
        .padding(.top, 20)
        
    }
    
    private var actionsView: some View {
        HStack {
            ForEach(app.buttons.indices, id: \.self) { index in
                HStack {
                    ScriptSelection(
                        button: Binding(
                            get: { self.app.buttons[index] },
                            set: { self.app.buttons[index] = $0 }),
                        title: (index + 1).description,
                        appName: self.app.name
                    )
                    if index != self.app.buttons.count - 1 {
                        Spacer()
                    }
                }
            }
        }
    }
}

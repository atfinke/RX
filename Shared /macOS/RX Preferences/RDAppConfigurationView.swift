//
//  RDAppConfigurationView.swift
//  RX Preferences
//
//  Created by Andrew Finke on 8/17/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import SwiftUI
import RXKit

struct RDAppConfigurationView: View {
    
    // MARK: - Properties -
    
    @EnvironmentObject var app: RXApp
    
    // MARK: - Body -
    
    var body: some View {
        let binding = Binding(
            get: { self.app.buttons[0] },
            set: { self.app.buttons[0] = $0 })
        
        return VStack {
            LeftText(
                text: app.name,
                font: Font.system(size: 17, weight: .semibold, design: .rounded)
            )
            Divider()
            Spacer()
            
            HStack {
                R1ButtonView(button: binding, state: .resting)
                Text("Resting").font(.system(size: 14, weight: .regular, design: .rounded))
                Spacer()
            }.frame(width: 100)
            
            HStack {
                R1ButtonView(button: binding, state: .pressed)
                Text("Pressed").font(.system(size: 14, weight: .regular, design: .rounded))
          Spacer()
            }.frame(width: 100)
             Spacer()
            ScriptSelection(button: Binding(
            get: { self.app.buttons[0] },
            set: { self.app.buttons[0] = $0 }), title: "Action")
        }
        .padding(.top, 5)
    .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

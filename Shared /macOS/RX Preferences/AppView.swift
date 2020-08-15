//
//  AppView.swift
//  RX Preferences
//
//  Created by Andrew Finke on 5/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import SwiftUI
import RXKit

struct AppView: View {

    @EnvironmentObject var app: RXApp

    var body: some View {
        RXNotifier.local.selected(app: app.name)
        return VStack {
            LeftText(
                text: app.name,
                font: Font.system(size: 17, weight: .semibold, design: .rounded)
            )
            Divider()
            HStack {
                VStack {
                    ColorCollectionHeaderView(text: "Resting")
                    RXBodyView(
                        buttons: Binding(
                            get: { self.app.buttons },
                            set: { self.app.buttons = $0 }),
                        state: .resting
                    )
                }
                Spacer(minLength: 35)
                VStack {
                    ColorCollectionHeaderView(text: "Pressed")
                    RXBodyView(
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
                ForEach(app.buttons.indices, id: \.self) { index in
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

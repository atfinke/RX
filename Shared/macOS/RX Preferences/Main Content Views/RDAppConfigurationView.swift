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

    @EnvironmentObject var preferences: RXPreferences
    @EnvironmentObject var app: RXApp
    let name: String // workaround for pain and suffering due to Big Sur SwiftUI regressions
    
    // MARK: - Body -

    var body: some View {
        RXNotifier.local.selected(app: app)

        let binding = Binding(
            get: { self.app.buttons[0] },
            set: { self.app.buttons[0] = $0 })

        return VStack {
            if !(preferences.customApps + preferences.defaultApps).contains(app) {
                Text("Select an App")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Text(name).font(.system(size: 17, weight: .semibold))
                Divider()
                Spacer()

                HStack {
                    VStack {
                        RXButtonView(button: binding, state: .resting, innerRadius: 10, lineWidth: 5)
                        Text("Resting").font(.system(size: 14, weight: .medium))
                        Spacer()
                    }.frame(width: 80)

                    VStack {
                        RXButtonView(button: binding, state: .pressed, innerRadius: 10, lineWidth: 5)
                        Text("Pressed").font(.system(size: 14, weight: .medium))
                        Spacer()
                    }.frame(width: 80)
                }.frame(height: 50)

                Spacer()
                ScriptSelection(button: binding,
                                title: "Select Action",
                                appName: app.name)
            }
        }
        .padding(.top, 5)
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

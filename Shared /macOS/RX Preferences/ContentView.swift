//
//  ContentView.swift
//  RX Preferences
//
//  Created by Andrew Finke on 6/30/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import RXKit
import SwiftUI

struct ContentView: View {
    @State var preferences = RXPreferences(rxButtons: RXHardware.numberOfButtons)

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

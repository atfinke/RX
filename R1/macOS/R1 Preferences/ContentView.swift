//
//  ContentView.swift
//  R1 Preferences
//
//  Created by Andrew Finke on 6/30/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import R1Kit
import SwiftUI

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

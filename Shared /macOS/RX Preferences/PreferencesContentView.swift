//
//  ContentView.swift
//  RX Preferences
//
//  Created by Andrew Finke on 6/30/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import RXKit
import SwiftUI

struct PreferencesContentView: View {
    
    // MARK: - Properties -
    
    @State var preferences: RXPreferences
    
    // MARK: - Body -
    
    var body: some View {
        return NavigationView {
            AppListView()
                .environmentObject(preferences)
                .frame(width: 160)
            Text("Select an App")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: preferences.hardware.edition == .R1 ? 620 : 360, height: 260)
    }
}

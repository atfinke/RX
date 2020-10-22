//
//  AppListView.swift
//  RX Preferences
//
//  Created by Andrew Finke on 6/29/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import SwiftUI
import RXKit

struct AppListView: View {
    
    // MARK: - Properties -
    
    @ObservedObject var preferences: RXPreferences
    private let openPanel = OpenPanelBridge()
    
    // MARK: - Body -
    
    var body: some View {
        VStack {
            List {
                sectionView(title: "Apps", apps: preferences.customApps)
                sectionView(title: "Other", apps: preferences.defaultApps)
            }.listStyle(SidebarListStyle())
            Divider()
            HStack {
                AppListToolbarRemoveButtonView(interface: preferences.interfaceHack)
                Spacer()
                Button(action: {
                    let existing = self.preferences.customApps.map { $0.bundleID }
                    if let (name, bundleID) = self.openPanel.selectApp(), !existing.contains(bundleID) {
                        let app = RXApp(name: name, bundleID: bundleID, buttonCount: self.preferences.hardware.edition.buttons)
                        self.preferences.customApps.append(app)
                        self.preferences.customApps.sort(by: { $0.name < $1.name })
                    }
                }) {
                    Text("+").font(Font.system(size: 14, weight: .medium))
                }
            }
            .padding(2)
            .frame(height: 20)
            .padding([.leading, .trailing], 7)
            .padding(.top, 0)
            .padding(.bottom, 7)
        }
    }
    
    func sectionView(title: String, apps: [RXApp]) -> some View {
        let hardwareEdition = preferences.hardware.edition
        return Section(header: Text(title)) {
            ForEach(apps) { app in
                if hardwareEdition == .R1 {
                    NavigationLink(destination: R1AppConfigurationView(name: app.name).environmentObject(app).environmentObject(preferences)) {
                        Text(app.name)
                    }
                } else if hardwareEdition == .RD {
                    NavigationLink(destination: RDAppConfigurationView(name: app.name).environmentObject(app).environmentObject(preferences)) {
                        Text(app.name)
                    }
                }
            }
        }
    }
    
}


struct AppListToolbarRemoveButtonView: View {
    
    // MARK: - Properties -
    
    @ObservedObject var interface: RXPreferences.InterfaceHack
    
    // MARK: - Body -
    
    var body: some View {
        Button(action: {
            RXNotifier.local.pressedRemove()
        }) {
            Text("-").font(Font.system(size: 14, weight: .medium))
        }.disabled(!interface.isDeleteEnabled)
        
    }
    
}

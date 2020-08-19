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
    
    @EnvironmentObject var preferences: RXPreferences
    private let openPanel = OpenPanelBridge()

    // MARK: - Body -
    
    var body: some View {
        let hardwareEdition = preferences.hardware.edition
        return VStack {
            List {
                Section(header: Text("Apps")) {
                    ForEach(preferences.customApps) { app in
                        if hardwareEdition == .R1 {
                            NavigationLink(destination: R1AppConfigurationView().environmentObject(app)) {
                                Text(app.name)
                            }
                        } else if hardwareEdition == .RD {
                            NavigationLink(destination: RDAppConfigurationView().environmentObject(app)) {
                                Text(app.name)
                            }
                        }
                    }
                }
                Section(header: Text("Other")) {
                    ForEach(preferences.defaultApps) { app in
                        if hardwareEdition == .R1 {
                            NavigationLink(destination: R1AppConfigurationView().environmentObject(app)) {
                                Text(app.name)
                            }
                        } else if hardwareEdition == .RD {
                            NavigationLink(destination: RDAppConfigurationView().environmentObject(app)) {
                                Text(app.name)
                            }
                        }
                    }
                }
            }.listStyle(SidebarListStyle())
            Divider()
            HStack {
                Button(action: {
                    RXNotifier.local.pressedRemove()
                }) {
                    Text("􀁏").font(Font.system(size: 14, weight: .medium, design: .rounded))
                }.buttonStyle(PlainButtonStyle())
                Spacer()
                Button(action: {
                    if let (name, bundleID) = self.openPanel.selectApp() {
                        let app = RXApp(name: name, bundleID: bundleID, buttonCount: self.preferences.hardware.edition.buttons)
                        self.preferences.customApps.append(app)
                        self.preferences.customApps.sort(by: { $0.name < $1.name })
                    }
                }) {
                    Text("􀁍").font(Font.system(size: 14, weight: .medium, design: .rounded))
                }.buttonStyle(PlainButtonStyle())
            }
            .padding(2)
            .frame(height: 20)
            .padding([.leading, .trailing], 7)
            .padding(.top, 0)
            .padding(.bottom, 7)
        }
    }
}

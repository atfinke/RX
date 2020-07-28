//
//  MasterListView.swift
//  R1 Preferences
//
//  Created by Andrew Finke on 6/29/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import SwiftUI
import R1Kit

struct MasterListView: View {

    @EnvironmentObject var preferences: R1Preferences
    private let openPanel = OpenPanelBridge()

    var body: some View {
        VStack {
            List {
                Section(header: Text("Apps")) {
                    ForEach(preferences.customApps) { app in
                        NavigationLink(destination: AppView().environmentObject(app)) {
                            Text(app.name)
                        }
                    }
                }
                Section(header: Text("Other")) {
                    ForEach(preferences.defaultApps) { app in
                        NavigationLink(destination: AppView().environmentObject(app)) {
                            Text(app.name)
                        }
                    }
                }
            }.listStyle(SidebarListStyle())
            Divider()
            HStack {
                Button(action: {
                    R1Notifier.local.pressedRemove()
                }) {
                    Text("􀁏").font(Font.system(size: 14, weight: .medium, design: .rounded))
                }.buttonStyle(PlainButtonStyle())
                Spacer()
                Button(action: {
                    if let (name, bundleID) = self.openPanel.selectApp() {
                        let app = R1App(name: name, bundleID: bundleID, buttonCount: RXHardware.numberOfButtons)
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

//
//  ContentView.swift
//  R1 Config
//
//  Created by Andrew Finke on 5/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import SwiftUI
import R1Kit

struct MasterView: View {
    
    @EnvironmentObject var settings: R1Settings
    private let openPanel = OpenPanelBridge()
    
    var body: some View {
        VStack {
            List {
                Section(header: Text("Apps")) {
                    ForEach(settings.customAppConfigs) { config in
                        NavigationLink(destination: DetailView().environmentObject(config)) {
                            Text(config.name)
                        }
                    }
                }
                Section(header: Text("Other")) {
                    ForEach(settings.defaultAppConfigs) { config in
                        NavigationLink(destination: DetailView().environmentObject(config)) {
                            Text(config.name)
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
                    if let app = self.openPanel.selectApp() {
                        let config = R1AppConfig(name: app, buttonCount: RXHardwareConfig.numberOfButtons)
                        self.settings.customAppConfigs.append(config)
                        self.settings.customAppConfigs.sort(by: { $0.name < $1.name })
                    }
                }) {
                    Text("􀁍").font(Font.system(size: 14, weight: .medium, design: .rounded))
                }.buttonStyle(PlainButtonStyle())
            }.padding(2)
                .frame(height: 20)
                .padding([.leading, .trailing], 7)
                .padding(.top, 0)
                .padding(.bottom, 7)
        }
    }
}

struct DetailView: View {
    
    @EnvironmentObject var config: R1AppConfig
    
    var body: some View {
        R1Notifier.local.selected(app: config.name)
        return VStack {
            LeftText(
                text: config.name,
                font: Font.system(size: 17, weight: .semibold, design: .rounded)
            )
            Divider()
            HStack {
                VStack {
                    ColorCollectionHeaderView(text: "Open")
                    R1BodyView(
                        buttons: Binding(
                            get: { self.config.buttons },
                            set: { self.config.buttons = $0 }),
                        state: .open
                    )
                }
                Spacer(minLength: 35)
                VStack {
                    ColorCollectionHeaderView(text: "Resting")
                    R1BodyView(
                        buttons: Binding(
                            get: { self.config.buttons },
                            set: { self.config.buttons = $0 }),
                        state: .resting
                    )
                }
                Spacer(minLength: 35)
                VStack {
                    ColorCollectionHeaderView(text: "Pressed")
                    R1BodyView(
                        buttons: Binding(
                            get: { self.config.buttons },
                            set: { self.config.buttons = $0 }),
                        state: .pressed
                    )
                }
            }.padding(.top, 5)
                .padding(.bottom, 18)
            
            Divider()
            
            LeftText(
                text: "Actions",
                font: Font.system(size: 15, weight: .medium, design: .rounded)
            ).padding(.top, 10)
            
            HStack {
                ForEach(config.buttons.indices, id: \.self){ index in
                    HStack {
                        ScriptSelection(
                            button: Binding(
                                get: { self.config.buttons[index] },
                                set: { self.config.buttons[index] = $0 }),
                            title: self.config.buttons[index].id.description
                        )
                        if index != RXHardwareConfig.numberOfButtons - 1 {
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

struct ContentView: View {
    @State var settings = R1Settings(rxButtons: RXHardwareConfig.numberOfButtons)
    
    var body: some View {
        return NavigationView {
            MasterView().environmentObject(settings)
                .frame(width: 160)
            Text("Select an App").frame(maxWidth: .infinity, maxHeight: .infinity)
        }.frame(width: 620, height: 260)
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
        //.environmentObject(UserData())
    }
}

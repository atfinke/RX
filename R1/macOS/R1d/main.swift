//
//  AppDelegate.swift
//  R1d
//
//  Created by Andrew Finke on 5/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import Cocoa
import R1Kit
import os.log

private let RXHardwareButtons = 4

class Main {
    
    // MARK: - Properties -
    
    private var manager: R1ConnectionManager?
    private lazy var notifications = Notifications(onAppChange: onAppChange, onMachineStateChange: onMachineStateChange)
    
    private var preferences = R1Preferences(writingEnabled: false, rxButtons: RXHardwareButtons)
    private var activeApp: R1App?
    
    // MARK: - Initalization -
    
    init() {
        manager = R1ConnectionManager(onConnect: {
            Helpers.showNotification(title: "R1 Connected", text: "-")
            if let name = self.notifications.activeAppName {
                self.onAppChange(name, nil)
            }
        }, onPress: { number in
            Helpers.pressed(button: number, for: self.activeApp)
        }, onError: { error in
            Helpers.showNotification(title: "R1 Error", text: error)
        })
    }
    
    // MARK: - Notifications -
    
    func onMachineStateChange(_ state: Notifications.MachineState) {
        switch state {
        case .on:
            if let app = self.activeApp {
                self.manager?.send(message: .appData(app))
            }
        case .sleeping:
            self.manager?.send(message: .ledsOff)
        case .off:
            self.manager?.send(message: .disconnect)
        }
    }
    
    func onAppChange(_ appName: String, _ lastAppName: String?) {
        if lastAppName == "R1 Preferences" {
            self.preferences = R1Preferences(writingEnabled: false, rxButtons: RXHardwareButtons)
        }
        
        let newApp: R1App
        
        let appPreferences = preferences.customApps + preferences.defaultApps
        if let activeApp = appPreferences.first(where: { $0.name == appName }) {
            newApp = activeApp
        } else if let def = appPreferences.first(where: { $0.name == "Default" }) {
            newApp = def
        } else {
            fatalError()
        }
        
        self.activeApp = newApp
        guard notifications.state == .on else { return }
        manager?.send(message: .appData(newApp))
    }
}

let main = Main()
RunLoop.main.run()

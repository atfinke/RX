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

    private let system = System()
    private let manager = R1ConnectionManager()

    private var preferences = R1Preferences(writingEnabled: false, rxButtons: RXHardwareButtons)
    private var activeR1App: R1App?

    // MARK: - Initalization -

    init() {
        system.onStateChange = onSystemStateChange(_:)
        manager.onUpdate = onR1Update(_:)
        
        R1Preferences.registerForUpdates {
            DispatchQueue.main.async {
                self.preferences = R1Preferences(writingEnabled: false, rxButtons: RXHardwareButtons)
                
                // load in new app object from preferences
                if let bundleID = self.activeR1App?.bundleID {
                    self.activeR1App = nil
                    self.updateActiveApp(to: bundleID)
                }
            }
        }
    }
    

    // MARK: - System -

    func onSystemStateChange(_ state: System.State) {
        DispatchQueue.main.async {
            switch state {
            case .on(let bundleID):
                self.updateActiveApp(to: bundleID)
                self.manager.isScanningEnabled = true
            case .sleeping:
                self.activeR1App = nil
                self.manager.send(message: .ledsOff)
                self.manager.isScanningEnabled = false
            }
        }
    }
    
    func updateActiveApp(to bundleID: String) {
        let newApp: R1App
        let apps = preferences.customApps + preferences.defaultApps
        if let activeApp = apps.first(where: { $0.bundleID == bundleID }) {
            newApp = activeApp
        } else if let def = apps.first(where: { $0.name == "Default" }) {
            newApp = def
        } else {
            fatalError()
        }

        let lastBundleID = activeR1App?.bundleID
        activeR1App = newApp
        if lastBundleID != activeR1App?.bundleID {
            manager.send(message: .appData(newApp))
        }
    }

    // MARK: - Connection -

    func onR1Update(_ update: R1ConnectionManager.Update) {
        DispatchQueue.main.async {
            switch update {
            case .connected:
                Helpers.showNotification(title: "R1 Connected", text: "-")
                if let app = self.activeR1App {
                    self.manager.send(message: .appData(app))
                }
            case .error(let error):
                Helpers.showNotification(title: "R1 Error", text: error)
            case .buttonPressed(let number):
                Helpers.pressed(button: number, for: self.activeR1App)
            }
        }
    }
}

let main = Main()
RunLoop.main.run()

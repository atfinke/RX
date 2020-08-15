//
//  AppDelegate.swift
//  RXd
//
//  Created by Andrew Finke on 5/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import Cocoa
import RXKit
import os.log

private let RXHardwareButtons = 4

class Main {
    
    // MARK: - Properties -

    private let system = System()
    private let manager = RXConnectionManager()

    private var preferences = RXPreferences(writingEnabled: false, rxButtons: RXHardwareButtons)
    private var activeRXApp: RXApp?

    // MARK: - Initalization -

    init() {
        system.onStateChange = onSystemStateChange(_:)
        manager.onUpdate = onRXUpdate(_:)
        
        RXPreferences.registerForUpdates {
            DispatchQueue.main.async {
                self.preferences = RXPreferences(writingEnabled: false, rxButtons: RXHardwareButtons)
                
                // load in new app object from preferences
                if let bundleID = self.activeRXApp?.bundleID {
                    self.activeRXApp = nil
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
                self.activeRXApp = nil
                self.manager.send(message: .ledsOff)
                self.manager.isScanningEnabled = false
            }
        }
    }
    
    func updateActiveApp(to bundleID: String) {
        let newApp: RXApp
        let apps = preferences.customApps + preferences.defaultApps
        if let activeApp = apps.first(where: { $0.bundleID == bundleID }) {
            newApp = activeApp
        } else if let def = apps.first(where: { $0.name == "Default" }) {
            newApp = def
        } else {
            fatalError()
        }

        let lastBundleID = activeRXApp?.bundleID
        activeRXApp = newApp
        if lastBundleID != activeRXApp?.bundleID {
            manager.send(message: .appData(newApp))
        }
    }

    // MARK: - Connection -

    func onRXUpdate(_ update: RXConnectionManager.Update) {
        DispatchQueue.main.async {
            switch update {
            case .connected(let name):
                Helpers.showNotification(title: "Connected to \(name)", text: nil)
                if let app = self.activeRXApp {
                    self.manager.send(message: .appData(app))
                }
            case .error(let error):
                Helpers.showNotification(title: "RX Error", text: error)
            case .buttonPressed(let number):
                Helpers.pressed(button: number, for: self.activeRXApp)
            }
        }
    }
}

let main = Main()
RunLoop.main.run()

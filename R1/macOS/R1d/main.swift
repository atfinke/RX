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
    private var activeApp: R1App?
    
    // MARK: - Initalization -
    
    init() {
        system.onStateChange = onSystemStateChange(_:)
        manager.onUpdate = onR1Update(_:)
    }
    
    // MARK: - System -
    
    func onSystemStateChange(_ state: System.State) {
        switch state {
        case .on(let appName):
            if let lastAppName = self.activeApp?.name, lastAppName == "R1 Preferences" {
                self.preferences = R1Preferences(writingEnabled: false, rxButtons: RXHardwareButtons)
            }
            let newApp: R1App
            let apps = preferences.customApps + preferences.defaultApps
            if let activeApp = apps.first(where: { $0.name == appName }) {
                newApp = activeApp
            } else if let def = apps.first(where: { $0.name == "Default" }) {
                newApp = def
            } else {
                fatalError()
            }
            activeApp = newApp
            manager.send(message: .appData(newApp))
        case .sleeping:
            manager.send(message: .ledsOff)
        case .off:
            manager.send(message: .disconnect)
        }
    }
    
    // MARK: - Connection -
    
    func onR1Update(_ update: R1ConnectionManager.Update) {
        switch update {
        case .connected:
            Helpers.showNotification(title: "R1 Connected", text: "-")
            if let app = self.activeApp {
                self.manager.send(message: .appData(app))
            }
        case .error(let error):
            Helpers.showNotification(title: "R1 Error", text: error)
        case .buttonPressed(let number):
            Helpers.pressed(button: number, for: self.activeApp)
        }
    }
}

let main = Main()
RunLoop.main.run()

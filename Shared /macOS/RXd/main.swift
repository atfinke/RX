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

class Main {
    
    // MARK: - Properties -
    
    private lazy var preferences: RXPreferences = {
        do {
            return try RXPreferences.loadFromDisk(writingEnabled: false)
        } catch {
            notificationsManager.show(title: "Inital setup not complete", text: "Open the RX Preferences app to finish setup")
            os_log("RX Preferences app hasn't completed inital setup", log: self.log, type: .error)
            fatalError()
        }
    }()
    
    private lazy var activeRXApp: RXApp = {
        guard let app = preferences.defaultApps.first(where: { $0.name == "Default" }) else {
            os_log("No default app", log: self.log, type: .error)
            fatalError()
        }
        return app
    }()
    
    private let macintosh = Macintosh()
    private let notificationsManager = NotificationsManager()
    private lazy var connectionManager: RXConnectionManager = {
        return RXConnectionManager(hardware: preferences.hardware)
    }()
    
    private let log = OSLog(subsystem: "com.andrewfinke.RX", category: "RXd Main")
    
    // MARK: - Initalization -
    
    init() {
        macintosh.onStateChange = onSystemStateChange(_:)
        connectionManager.onUpdate = onRXUpdate(_:)
        
        RXPreferences.registerForUpdates {
            os_log("Observed update", log: self.log, type: .info)
            DispatchQueue.main.async {
                do {
                    let preferences = try RXPreferences.loadFromDisk(writingEnabled: false)
                    self.preferences = preferences
                    
                    os_log("loaded new prefs", log: self.log, type: .info)
                    
                    self.updateActiveApp(to: self.activeRXApp.bundleID)
                } catch {
                    if self.connectionManager.isConnected {
                        self.connectionManager.send(message: .disconnect)
                        os_log("RX Preferences app triggered reset", log: self.log, type: .info)
                        exit(0) // Path triggered by RX Prefs reset
                    } else {
                        os_log("RX Preferences couldn't be read", log: self.log, type: .error)
                    }
                }
            }
        }
    }
    
    // MARK: - System -

    func onSystemStateChange(_ state: Macintosh.State) {
        DispatchQueue.main.async {
            switch state {
            case .on(let bundleID):
                self.updateActiveApp(to: bundleID)
                self.connectionManager.isScanningEnabled = true
            case .sleeping:
                self.connectionManager.send(message: .ledsOff)
                self.connectionManager.isScanningEnabled = false
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

        let previousColors = activeRXApp.buttons.map { $0.colors }
        if previousColors != newApp.buttons.map({ $0.colors }) {
            os_log("Diff colors", log: log, type: .info)
            connectionManager.send(message: .appData(newApp))
        }
        
        activeRXApp = newApp
    }

    // MARK: - Connection -

    func onRXUpdate(_ update: RXConnectionManager.ListenerUpdate) {
        func show(title: String, text: String?) {
            notificationsManager.show(title: title, text: text)
        }
        
        DispatchQueue.main.async {
            switch update {
            case .connected(let name):
                show(title: "Connected to \(name)", text: nil)
                self.connectionManager.send(message: .appData(self.activeRXApp))
            case .error(let error):
                show(title: "\(self.preferences.hardware.edition.rawValue) Error", text: error)
            case .buttonPressed(let number):
                if number <= self.activeRXApp.buttons.count, let action = self.activeRXApp.buttons[number - 1].action {
                    action.run()
                } else {
                    show(title: "\(self.preferences.hardware.edition.rawValue) Not Configured",
                         text: "Pressed button \(number) with no action set for \(self.activeRXApp.name)")
                }
            }
        }
    }
}


let main = Main()
RunLoop.main.run()

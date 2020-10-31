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

class AppDelegate: NSObject, NSApplicationDelegate {
    
    // MARK: - Properties -
    
    private lazy var preferences: RXPreferences = {
        do {
            return try RXPreferences.loadFromDisk(writingEnabled: false)
        } catch {
            notificationsManager.show(title: "Inital Setup Not Complete", text: "Open the RX Preferences app to finish setup")
            os_log("RX Preferences app hasn't completed inital setup", log: self.log, type: .error)
            exit(0)
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
    
    // We don't want to show connected notification every time someone unlocks device, annoying
    private var shouldShowConnectionNotification = true
    
    private let log = OSLog(subsystem: "com.andrewfinke.RX", category: "RXd Main")
    
    // MARK: - Initalization -
    
    override init() {
        super.init()
        
        notificationsManager.auth()
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
                    // only possible if there was previously valid prefs object
                    self.connectionManager.send(message: .disconnect)
                    os_log("RX Preferences app triggered reset", log: self.log, type: .info)
                    self.notificationsManager.show(title: "Quitting", text: "RX Preferences triggered a reset")
                    exit(0) // Path triggered by RX Prefs reset
                }
            }
        }
    }
    
    // MARK: - Delegate Termination -
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        os_log("applicationShouldTerminate: called", log: self.log, type: .info)
        if let rx = connectionManager.peripheral, rx.state == .connected {
            os_log("applicationShouldTerminate: still connected", log: self.log, type: .info)
            connectionManager.send(message: .disconnect)
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                os_log("applicationShouldTerminate: replying", log: self.log, type: .info)
                NSApplication.shared.reply(toApplicationShouldTerminate: true)
            }
            return .terminateLater
        } else {
            os_log("applicationShouldTerminate: not connected, terminate", log: self.log, type: .info)
            return .terminateNow
        }
    }
    
    // MARK: - System -
    
    func onSystemStateChange(_ state: Macintosh.State) {
        DispatchQueue.main.async {
            switch state {
            case .on(let bundleID):
                self.updateActiveApp(to: bundleID)
            case .sleeping:
                self.connectionManager.isConnectingEnabled = false
                self.connectionManager.send(message: .disconnect)
            case .wakingFromSleep:
                self.connectionManager.isConnectingEnabled = true
                self.connectionManager.attemptConnection()
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
        
        connectionManager.send(message: .appData(newApp))
        activeRXApp = newApp
    }
    
    // MARK: - Connection -
    
    func onRXUpdate(_ update: RXConnectionManager.ListenerUpdate) {
        func show(title: String, text: String?) {
            notificationsManager.show(title: title, text: text)
        }
        
        DispatchQueue.main.async {
            switch update {
            case .connected:
                self.connectionManager.send(message: .appData(self.activeRXApp))
            case .updatedName(let name):
                if self.shouldShowConnectionNotification {
                    self.shouldShowConnectionNotification = false
                    show(title: "Connected to \(name)", text: nil)
                }
            case .error(let error):
                self.shouldShowConnectionNotification = true // Show when reconnected
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

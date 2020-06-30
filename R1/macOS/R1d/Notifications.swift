//
//  Notifications.swift
//  R1d
//
//  Created by Andrew Finke on 6/29/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import AppKit
import os.log

class Notifications {
    
    // MARK: - Properties -
    
    var activeAppName: String?
    var isSleeping = false
    private let log = OSLog(subsystem: "com.andrewfinke.R1", category: "notifications")
    
    // MARK: - Initalization -
    
    init(onAppChange: @escaping (_ appName: String, _ lastAppName: String?) -> Void, onSleepStateChange: @escaping (_ isSleeping: Bool) -> Void) {
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: nil,
            using: { notification in
                let appName = (notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication)?.localizedName ?? "N/A"
                os_log("%{public}s: didActivateApplicationNotification: %{public}s", log: self.log, type: .info, #function, appName)
                
                let lastAppName = self.activeAppName
                self.activeAppName = appName
                onAppChange(appName, lastAppName)
        })
        
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: nil,
            using: { _ in
                os_log("%{public}s: willSleepNotification", log: self.log, type: .info, #function)
                self.isSleeping = true
                onSleepStateChange(self.isSleeping)
        })
        
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: nil,
            using: { _ in
                os_log("%{public}s: didWakeNotification", log: self.log, type: .info, #function)
                self.isSleeping = false
                onSleepStateChange(self.isSleeping)
        })
    }
}

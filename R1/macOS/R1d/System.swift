//
//  System.swift
//  R1d
//
//  Created by Andrew Finke on 6/29/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import AppKit
import os.log

class System {
    
    enum State {
        case on(appName: String), sleeping, off
    }
    
    // MARK: - Properties -
    
    var onStateChange: ((_ state: State) -> Void)?
    private let log = OSLog(subsystem: "com.andrewfinke.R1", category: "notifications")
    
    // MARK: - Initalization -
    
    init() {
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: nil,
            using: { notification in
                let appName = (notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication)?.localizedName ?? "N/A"
                os_log("%{public}s: didActivateApplicationNotification: %{public}s", log: self.log, type: .info, #function, appName)

                self.onStateChange?(.on(appName: appName))
        })
        
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.willPowerOffNotification,
            object: nil,
            queue: nil,
            using: { _ in
                os_log("%{public}s: willPowerOffNotification", log: self.log, type: .info, #function)
                self.onStateChange?(.off)
        })
        
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: nil,
            using: { _ in
                os_log("%{public}s: willSleepNotification", log: self.log, type: .info, #function)
                self.onStateChange?(.sleeping)
        })
        
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: nil,
            using: { _ in
                os_log("%{public}s: didWakeNotification", log: self.log, type: .info, #function)
                guard let appName = NSWorkspace.shared.frontmostApplication?.localizedName else { return }
                self.onStateChange?(.on(appName: appName))
        })
    }
}

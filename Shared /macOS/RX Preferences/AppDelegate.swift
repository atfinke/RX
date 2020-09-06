//
//  AppDelegate.swift
//  RX Preferences
//
//  Created by Andrew Finke on 5/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import Cocoa
import SwiftUI
import RXKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var window: NSWindow!
    var rxdTimer: Timer?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.center()
        showWindow()
        
        guard let menu = NSApp.menu?.item(withTitle: "File")?.submenu else {
            fatalError()
        }
        
        let seperator = NSMenuItem.separator()
        menu.addItem(seperator)
        let item = NSMenuItem(title: "Reset", action: #selector(reset), keyEquivalent: "")
        menu.addItem(item)
    }
    
    func showWindow() {
        rxdTimer?.invalidate()
        
        do {
            let preferences = try RXPreferences.loadFromDisk(writingEnabled: true)
            let contentView = PreferencesContentView(preferences: preferences)
            
            window.styleMask = [.titled, .closable, .miniaturizable, .fullSizeContentView]
            window.contentView = NSHostingView(rootView: contentView)
            
            func updateRXDStatus() {
                let rxdBundleID = "com.andrewfinke.RXd"
                
                // Does not work when RXd launched from Xcode
                if NSRunningApplication.runningApplications(withBundleIdentifier: rxdBundleID).count == 0 {
                    window.title = "RX Preferences - RXd Not Running"
                } else {
                    window.title = "RX Preferences"
                }
            }
            
            updateRXDStatus()
            rxdTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
                updateRXDStatus()
            })
        } catch {
            window.styleMask = [.titled, .closable, .fullSizeContentView]
            let contentView = SetupView(onFinish: { hardware in
                hardware.save()
                self.showWindow()
            })
            window.contentView = NSHostingView(rootView: contentView)
            window.title = "RX Setup"
        }
        window.makeKeyAndOrderFront(nil)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    @objc
    func reset() {
        do {
            try FileManager.default.removeItem(at: RXURL.support)
        } catch {
            fatalError()
        }
        RXPreferences.triggerRXdUpdate()
        showWindow()
    }
    
}

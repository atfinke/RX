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
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.center()
        showWindow()
    }
    
    func showWindow() {
        do {
            let preferences = try RXPreferences.loadFromDisk(writingEnabled: true)
            let contentView = PreferencesContentView(preferences: preferences)
            
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
            window.contentView = NSHostingView(rootView: contentView)
            window.title = "RX Preferences"
        } catch {
            window.styleMask = [.titled, .closable, .fullSizeContentView]
            let contentView = SNContentView(onFinish: { hardware in
                hardware.save()
                self.showWindow()
            })
            window.contentView = NSHostingView(rootView: contentView)
        }
        window.makeKeyAndOrderFront(nil)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
}

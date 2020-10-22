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

    // MARK: - Properties -
    
    var window: NSWindow!
    var rxdTitleNoticeTimer: Timer?
    
    // MARK: - NSApplicationDelegate -

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

        menu.addItem(NSMenuItem.separator())
        let showItem = NSMenuItem(title: "Show RX Support in Finder", action: #selector(showSupport), keyEquivalent: "")
        menu.addItem(showItem)
        
        menu.addItem(NSMenuItem.separator())
        let resetItem = NSMenuItem(title: "Reset", action: #selector(reset), keyEquivalent: "")
        menu.addItem(resetItem)
    }

    func showWindow() {
        rxdTitleNoticeTimer?.invalidate()

        do {
            let preferences = try RXPreferences.loadFromDisk(writingEnabled: true)
            RXPreferences.triggerRXdUpdate()
            
            let contentView = PreferencesContentView(preferences: preferences)

            window.styleMask = [.titled, .closable, .miniaturizable, .fullSizeContentView]
            window.contentView = NSHostingView(rootView: contentView)

            updateRXDStatus()
            rxdTitleNoticeTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] _ in
                self?.updateRXDStatus()
            })
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                guard !RXPreferences.isRXdAlive(),
                      let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.andrewfinke.RXd") else { return }
                
                let alert = NSAlert()
                alert.messageText = "RXd Not Running"
                alert.informativeText = "RXd must be running to connect to your device. Would you like to launch it in the background now?"
                alert.alertStyle = NSAlert.Style.warning
                alert.addButton(withTitle: "Yes")
                alert.addButton(withTitle: "No")
                guard alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn else {
                    return
                }
                
                NSWorkspace.shared.openApplication(at: url, configuration: .init(), completionHandler: { _, _ in
                    self.updateRXDStatus()
                })
            }
        } catch {
            let contentView = SetupView(onFinish: { hardware in
                hardware.save()
                self.showWindow()
            })
            
            window.styleMask = [.titled, .closable, .fullSizeContentView]
            window.contentView = NSHostingView(rootView: contentView)
            window.title = "RX Setup"
        }
        window.makeKeyAndOrderFront(nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func updateRXDStatus() {
        DispatchQueue.main.async {
            // NSRunningApplication.runningApplications does not work 100% of the time
            if RXPreferences.isRXdAlive() {
                // crashed DTK
                self.window.title = "RX Preferences"
            } else {
                self.window.title = "RX Preferences - RXd Not Open"
            }
        }
    }

    @objc
    func showSupport() {
        NSWorkspace.shared.selectFile(RXURL.support.path, inFileViewerRootedAtPath: "")
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

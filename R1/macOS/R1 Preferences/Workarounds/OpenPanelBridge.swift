//
//  OpenPanelBridge.swift
//  R1 Preferences
//
//  Created by Andrew Finke on 5/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import Cocoa
import R1Kit

class OpenPanelBridge {

    func selectR1Script() -> R1Script? {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedFileTypes = ["scpt"]
        if panel.runModal() == .OK,
            let url = panel.url,
            let name = url.lastPathComponent.split(separator: ".").first {
            let dest = R1URL.newScript()
            do {
                try FileManager.default.copyItem(atPath: url.path, toPath: dest.path)
            } catch {
                return nil
            }
            return R1Script(name: String(name), path: dest)
        }
        return nil
    }
    
    func selectApp() -> String? {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedFileTypes = ["app"]
        panel.directoryURL = URL(string: "/Applications")
        if panel.runModal() == .OK,
            let url = panel.url,
            let name = url.lastPathComponent.split(separator: ".").first {
            return String(name)
        }
        return nil
    }
}

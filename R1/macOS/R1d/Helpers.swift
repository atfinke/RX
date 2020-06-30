//
//  Helpers.swift
//  R1d
//
//  Created by Andrew Finke on 5/26/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import Foundation
import R1Kit

struct Helpers {

    // MARK: - Input -
    
    static func pressed(button: Int, for app: R1App?) {
        guard let app = app else {
            showNotification(title: "R1 Not Configured", text: "Pressed button with no app")
            return
        }
        
        if button <= app.buttons.count, let action = app.buttons[button - 1].action {
            run(script: action)
        } else {
            showNotification(title: "R1 Not Configured", text: "Pressed button \(button) with no script for \(app.name)")
        }
    }
    
    // MARK: - Scripts -
    
    static func run(script: R1Script) {
        let process = Process()
        process.launchPath = "/usr/bin/osascript"
        process.arguments = [script.path.path]
        process.launch()
    }
    
    static func showNotification(title: String, text: String) {
        let source = """
        display notification "\(text)" with title "\(title)" sound name "Ping"
        """

        guard let script = NSAppleScript(source: source) else {
            return
        }
        script.executeAndReturnError(nil)
    }
    
}

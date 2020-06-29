//
//  Helpers.swift
//  R1 Helper
//
//  Created by Andrew Finke on 5/26/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import Cocoa
import R1Kit

struct Helpers {
    
    static func activeApp() -> String? {
        return NSWorkspace().frontmostApplication?.localizedName
    }

    static func pressed(button: Int, for config: R1AppConfig?) {
        guard let config = config else {
            ScriptRunner.showNotification(title: "R1 Not Configured", text: "Pressed button with no config")
            return
        }
        
        if button <= config.buttons.count, let action = config.buttons[button - 1].action {
            ScriptRunner.run(script: action)
        } else {
            ScriptRunner.showNotification(title: "R1 Not Configured", text: "Pressed button \(button) with no script for \(config.name)")
        }
    }
}

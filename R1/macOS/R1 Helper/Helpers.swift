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
        
        if button == 1, let script = config.firstScript {
            ScriptRunner.run(script: script)
        } else if button == 2, let script = config.secondScript {
            ScriptRunner.run(script: script)
        } else if button == 3, let script = config.thirdScript {
            ScriptRunner.run(script: script)
        } else if button == 4, let script = config.fourthScript {
            ScriptRunner.run(script: script)
        } else {
            ScriptRunner.showNotification(title: "R1 Not Configured", text: "Pressed button \(button) with no script for \(config.name)")
        }
    }
}

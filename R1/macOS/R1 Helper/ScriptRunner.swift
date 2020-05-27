//
//  ScriptRunner.swift
//  R1 Helper
//
//  Created by Andrew Finke on 5/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import R1Kit

struct ScriptRunner {
    
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

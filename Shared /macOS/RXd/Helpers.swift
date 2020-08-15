//
//  Helpers.swift
//  RXd
//
//  Created by Andrew Finke on 5/26/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import Foundation
import RXKit

struct Helpers {

    // MARK: - Input -

    static func pressed(button: Int, for app: RXApp?) {
        guard let app = app else {
            showNotification(title: "RX Not Configured", text: "Pressed button with no app")
            return
        }

        if button <= app.buttons.count, let action = app.buttons[button - 1].action {
            run(script: action)
        } else {
            showNotification(title: "RX Not Configured", text: "Pressed button \(button) with no script for \(app.name)")
        }
    }

    // MARK: - Scripts -

    static func run(script: RXScript) {
        let process = Process()
        process.launchPath = "/usr/bin/osascript"
        process.arguments = [script.fileURL.path]
        process.launch()
    }

    static func showNotification(title: String, text: String?) {
        let source = """
        display notification "\(text ?? "")" with title "\(title)"
        """

        guard let script = NSAppleScript(source: source) else {
            return
        }
        script.executeAndReturnError(nil)
    }

}

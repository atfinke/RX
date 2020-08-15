//
//  ColorPanelBridge.swift
//  RX Preferences
//
//  Created by Andrew Finke on 5/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import SwiftUI
import RXKit

class ColorPanelBridge {

    // MARK: - Properties -

    var update: ((RXColor) -> Void)?
    private let panel = NSColorPanel.shared

    // MARK: - Helpers -

    func show(current: RXColor, update: @escaping (RXColor) -> Void) {
        panel.setTarget(nil)
        panel.color = NSColor(red: CGFloat(current.red), green: CGFloat(current.green), blue: CGFloat(current.blue), alpha: 1)
        panel.setTarget(self)
        panel.setAction(#selector(selectedColor(sender:)))
        panel.makeKeyAndOrderFront(self)
        panel.isContinuous = true
        panel.showsAlpha = false
        self.update = update
    }

    @objc func selectedColor(sender: NSColorPanel) {
        update?(RXColor(sender.color))
        NSApp.mainWindow?.makeKey()
    }
}

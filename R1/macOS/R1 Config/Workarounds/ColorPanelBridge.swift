//
//  ColorPanelBridge.swift
//  R1 Config
//
//  Created by Andrew Finke on 5/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import SwiftUI
import R1Kit

class ColorPanelBridge {
    
    // MARK: - Properties -
    
    var update: ((R1Color) -> Void)?
    
    // MARK: - Helpers -
    
    func show(_ update: @escaping (R1Color) -> Void) {
        let panel = NSColorPanel.shared
        panel.setTarget(self)
        panel.setAction(#selector(selectedColor(sender:)))
        panel.makeKeyAndOrderFront(self)
        panel.isContinuous = true
        panel.showsAlpha = false
        self.update = update
    }
    
    @objc func selectedColor(sender: NSColorPanel) {
        update?(R1Color(sender.color))
    }
}

//
//  ActivityIndicator.swift
//  RX Preferences
//
//  Created by Andrew Finke on 9/1/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import Cocoa
import SwiftUI

struct ActivityIndicator: NSViewRepresentable {

    func makeNSView(context: Context) -> some NSView {
        let size = 20
        let indicator = NSProgressIndicator(frame: NSRect(x: 0, y: 0, width: size, height: size))
        indicator.style = .spinning
        indicator.startAnimation(nil)
        return indicator
    }
    
    func updateNSView(_ nsView: NSViewType, context: Context) {
        
    }
}

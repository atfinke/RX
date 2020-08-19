//
//  RDButtonView.swift
//  RX Preferences
//
//  Created by Andrew Finke on 8/17/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import SwiftUI
import RXKit

struct RDButtonView: View {
    
    // MARK: - Properties -
    
    @Binding var button: RXAppButton
    let state: RXBodyViewStateType
    
    private let radius: CGFloat = 6
    private let colorPanel = ColorPanelBridge()
    
    var color: RXColor {
        get {
            switch self.state {
            case .resting:
                return button.colors.resting
            case .pressed:
                return button.colors.pressed
            }
        }
        set {
            switch self.state {
            case .resting:
                button.colors.resting = newValue
            case .pressed:
                button.colors.pressed = newValue
            }
        }
    }
    
    // MARK: - Body -
    
    var body: some View {
        let color: RXColor
        switch self.state {
        case .resting:
            color = button.colors.resting
        case .pressed:
            color = button.colors.pressed
        }
        let swiftColor = color.swiftColor
        
        return Circle()
            .fill(swiftColor)
            .frame(width: radius * 2, height: radius * 2)
          
    }
    
    private func update(color: RXColor) {
        switch state {
        case .resting:
            button.colors.resting = color
        case .pressed:
            button.colors.pressed = color
        }
    }
}

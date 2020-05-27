//
//  R1Button.swift
//  R1 Config
//
//  Created by Andrew Finke on 5/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import SwiftUI
import R1Kit

struct R1ButtonView: View {
    
    // MARK: - Properties -
    
    @Binding var color: R1Color
    private let radius: CGFloat = 5
    private let colorPanel = ColorPanelBridge()
    
    // MARK: - Body -
    
    var body: some View {
        Button(action: {
            self.colorPanel.show { color in
                self.color = color
            }
        }, label: {
            ZStack {
                Circle()
                    .fill(Color(.windowBackgroundColor))
                    .frame(width: radius * 2, height: radius * 2)
                
                Circle()
                    .stroke(color.swiftColor, lineWidth: 3)
                    .frame(width: radius * 2, height: radius * 2)
            }
        }).buttonStyle(PlainButtonStyle())
            
    }
}


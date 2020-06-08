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
    
    @Binding var button: R1AppButton
    let state: R1BodyViewType
    
    private let radius: CGFloat = 5
    private let colorPanel = ColorPanelBridge()
    
    var color: R1Color {
        get {
            return button.colors.open
        }
        set {
            button.colors.open = newValue
        }
    }
    
    // MARK: - Body -
    
    var body: some View {
        let color: Color
        switch self.state {
        case .open:
            color = button.colors.open.swiftColor
        case .resting:
            color = button.colors.resting.swiftColor
        case .pressed:
            color = button.colors.pressed.swiftColor
        }
        
        return Button(action: {
            self.colorPanel.show { color in
                self.update(color: color)
            }
        }, label: {
            ZStack {
                Circle()
                    .fill(Color(.windowBackgroundColor))
                    .frame(width: radius * 2, height: radius * 2)
                
                Circle()
                    .stroke(color, lineWidth: 3)
                    .frame(width: radius * 2, height: radius * 2)
            }
            .onDrag { () -> NSItemProvider in
                return NSItemProvider(object: R1ColorProvider(self.color))
            }
            .onDrop(of: [R1ColorProvider.identifier], isTargeted: nil) { providers -> Bool in
                guard let item = providers.first(where: { $0.hasItemConformingToTypeIdentifier(R1ColorProvider.identifier)}) else {
                    return false
                }
                _ = item.loadObject(ofClass: R1ColorProvider.self) { object, _ in
                    guard let color = (object as? R1ColorProvider)?.color else { return }
                    DispatchQueue.main.async {
                        self.update(color: color)
                    }
                }
                return true
            }
        }).buttonStyle(PlainButtonStyle())
            
    }
    
    private func update(color: R1Color) {
        switch state {
        case .open:
            button.colors.open = color
        case .resting:
            button.colors.resting = color
        case .pressed:
            button.colors.pressed = color
        }
    }
}


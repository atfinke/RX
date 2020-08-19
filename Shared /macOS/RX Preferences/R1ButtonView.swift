//
//  RXButtonView.swift
//  RX Preferences
//
//  Created by Andrew Finke on 5/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import SwiftUI
import RXKit

struct R1ButtonView: View {

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

        return Button(action: {
            self.colorPanel.show(current: color) { newColor in
                self.update(color: newColor)
            }
        }, label: {
            ZStack {
                Circle()
                    .fill(Color(.windowBackgroundColor))
                    .frame(width: radius * 2, height: radius * 2)

                Circle()
                    .stroke(swiftColor, lineWidth: 3.5)
                    .frame(width: radius * 2, height: radius * 2)
            }
            .onDrag { () -> NSItemProvider in
                return NSItemProvider(object: RXColorProvider(self.color))
            }
            .onDrop(of: [RXColorProvider.identifier], isTargeted: nil) { providers -> Bool in
                guard let item = providers.first(where: { $0.hasItemConformingToTypeIdentifier(RXColorProvider.identifier)}) else {
                    return false
                }
                _ = item.loadObject(ofClass: RXColorProvider.self) { object, _ in
                    guard let color = (object as? RXColorProvider)?.color else { return }
                    DispatchQueue.main.async {
                        self.update(color: color)
                    }
                }
                return true
            }
        }).buttonStyle(PlainButtonStyle())

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

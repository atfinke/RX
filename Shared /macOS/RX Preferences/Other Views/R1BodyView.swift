//
//  R1BodyView.swift
//  RX Preferences
//
//  Created by Andrew Finke on 5/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import SwiftUI
import RXKit

struct R1BodyView: View {

    // MARK: - Properties -

    @Binding var buttons: [RXAppButton]
    let state: RXBodyViewStateType

    private var colors: [RXColor] {
        switch self.state {
        case .resting:
            return buttons.map { $0.colors.resting }
        case .pressed:
            return buttons.map { $0.colors.pressed }
        }
    }

    // MARK: - Body -

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.windowBackgroundColor))
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.primary, lineWidth: 3)

            HStack {
                ForEach(buttons.indices, id: \.self) { index in
                    HStack {
                        RXButtonView(
                            button: Binding(
                                get: { self.buttons[index] },
                                set: { self.buttons[index] = $0 }),
                            state: self.state,
                            innerRadius: 6,
                            lineWidth: 3.5
                        )
                        if index != self.buttons.count - 1 {
                            Spacer()
                        }
                    }
                }
            }
            .padding(12)
            .padding(.horizontal, 10)
        }
        .frame(height: 40)
        .onDrag { () -> NSItemProvider in
            return NSItemProvider(object: RXColorsProvider(self.colors))
        }
        .onDrop(of: [RXColorsProvider.identifier], isTargeted: nil) { providers -> Bool in
            guard let item = providers.first(where: { $0.hasItemConformingToTypeIdentifier(RXColorsProvider.identifier)}) else {
                return false
            }
            _ = item.loadObject(ofClass: RXColorsProvider.self) { object, _ in
                guard let colors = (object as? RXColorsProvider)?.colors else { return }
                DispatchQueue.main.async {
                    for (index, color) in colors.enumerated() {
                        self.update(color: color, index: index)
                    }
                }
            }
            return true
        }
    }

     // MARK: - Helpers -

    private func update(color: RXColor, index: Int) {
        switch state {
        case .resting:
            self.buttons[index].colors.resting = color
        case .pressed:
            self.buttons[index].colors.pressed = color
        }
    }
}

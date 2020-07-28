//
//  R1BodyView.swift
//  R1 Preferences
//
//  Created by Andrew Finke on 5/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import SwiftUI
import R1Kit

struct R1BodyView: View {

    @Binding var buttons: [R1AppButton]
    let state: R1BodyViewType

    private var colors: [R1Color] {
        switch self.state {
        case .resting:
            return buttons.map({ $0.colors.resting })
        case .pressed:
            return buttons.map({ $0.colors.pressed })
        }
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.windowBackgroundColor))
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.primary, lineWidth: 3)

            HStack {
                ForEach(buttons.indices, id: \.self) { index in
                    HStack {
                        R1ButtonView(
                            button: Binding(
                                get: { self.buttons[index] },
                                set: { self.buttons[index] = $0 }),
                            state: self.state
                        )
                        if index != RXHardware.numberOfButtons - 1 {
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
            return NSItemProvider(object: R1ColorsProvider(self.colors))
        }
        .onDrop(of: [R1ColorsProvider.identifier], isTargeted: nil) { providers -> Bool in
            guard let item = providers.first(where: { $0.hasItemConformingToTypeIdentifier(R1ColorsProvider.identifier)}) else {
                return false
            }
            _ = item.loadObject(ofClass: R1ColorsProvider.self) { object, _ in
                guard let colors = (object as? R1ColorsProvider)?.colors else { return }
                DispatchQueue.main.async {
                    for (index, color) in colors.enumerated() {
                        self.update(color: color, index: index)
                    }
                }
            }
            return true
        }
    }

    private func update(color: R1Color, index: Int) {
        switch state {
        case .resting:
            self.buttons[index].colors.resting = color
        case .pressed:
            self.buttons[index].colors.pressed = color
        }
    }
}

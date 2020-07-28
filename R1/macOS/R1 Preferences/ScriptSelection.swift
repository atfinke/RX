//
//  ScriptSelection.swift
//  R1 Preferences
//
//  Created by Andrew Finke on 5/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import SwiftUI
import R1Kit

struct ScriptSelection: View {

    // MARK: - Properties -

    @Binding var button: R1AppButton

    let title: String
    private let openPanel = OpenPanelBridge()

    // MARK: - Body -

    var body: some View {
        VStack {
            Button(action: {
                if let script = self.openPanel.selectR1Script() {
                    self.button.action = script
                }
            }, label: {
                Text(title)
                    .frame(width: 65)
            })
            scriptLabel
                .font(.system(size: 9, weight: .regular, design: .monospaced))
                .multilineTextAlignment(.center)
                .frame(height: 20)
        }
    }

    private var scriptLabel: some View {
        if let script = button.action {
            return Text(script.name)
        } else {
            return Text("-")
        }
    }
}

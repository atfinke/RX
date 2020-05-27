//
//  ScriptSelection.swift
//  R1 Config
//
//  Created by Andrew Finke on 5/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import SwiftUI
import R1Kit

struct ScriptSelection: View {
    
    // MARK: - Properties -
    
    @Binding var script: R1Script?
    let button: String
    
    private let openPanel = OpenPanelBridge()
    
    // MARK: - Body -
    
    var body: some View {
        VStack {
            Button(action: {
                if let script = self.openPanel.selectR1Script() {
                    self.script = script
                }
            }, label: {
                Text(button).frame(width: 65)
            })
            scriptLabel
                .font(.system(size: 9, weight: .regular, design: .monospaced))
                .multilineTextAlignment(.center)
                .frame(height: 20)
        }
    }
    
    private var scriptLabel: some View {
        if let script = self.script {
            return Text(script.name)
        } else {
            return Text("-")
        }
    }
}

//
//  ScriptSelection.swift
//  RX Preferences
//
//  Created by Andrew Finke on 5/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import SwiftUI
import RXKit

struct ScriptSelection: View {

    // MARK: - Properties -

    @Binding var button: RXAppButton

    let title: String
    let appName: String
    private let openPanel = OpenPanelBridge()

    // MARK: - Body -

    var body: some View {
        VStack {
            Button(action: {
                if let script = self.openPanel.selectRXScript(appName: self.appName) {
                    self.button.action = script
                }
            }, label: {
                Text(title)
                    .frame(minWidth: 65)
            })
            scriptLabel
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .multilineTextAlignment(.center)
                .frame(height: 20)
                .onTapGesture {
                    guard let url = self.button.action?.fileURL else { return }
                    NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: "")
                }
                .onHover { isHovering in
                    if isHovering && self.button.action?.fileURL != nil {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
        }
    }

    private var scriptLabel: some View {
        if let script = button.action {
            return Text(script.name)
        } else {
            return Text("No Action Set")
        }
    }
}

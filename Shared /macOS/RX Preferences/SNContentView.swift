//
//  SNContentView.swift
//  RX Preferences
//
//  Created by Andrew Finke on 8/16/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import SwiftUI
import Combine
import RXKit

struct SNContentView: View {
    
    // MARK: - Properties -
    
    @State private var edition: RXHardware.Edition?
    @State private var serialNumber: String = ""
    
    let onFinish: (RXHardware) -> Void
    
    // MARK: - Body -
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Enter Serial Number")
                .font(.system(size: 16, weight: .medium, design: .rounded))
            TextField("", text: $serialNumber)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .frame(width: 80)
                .onReceive(Just(serialNumber)) { newValue in
                    let nums = newValue.filter { "0123456789".contains($0) }
                    if nums != newValue {
                        self.serialNumber = nums
                    }
                    
                    var newEdition: RXHardware.Edition?
                    for (edition, serials) in RXSerials.store where serials.contains(self.serialNumber) {
                        newEdition = edition
                    }
                    self.edition = newEdition
            }
            
            Button(action: {
                guard let edition = self.edition else { fatalError() }
                self.onFinish(RXHardware(serialNumber: self.serialNumber, edition: edition))
            }, label: {
                Text(edition != nil ? "Done" : "Invalid")
                    .frame(width: 60)
            }).disabled(edition == nil)
        }
        .frame(width: 220, height: 140)
    }
}

//
//  SetupView.swift
//  RX Preferences
//
//  Created by Andrew Finke on 9/1/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//
//

import SwiftUI
import Combine
import RXKit

struct SetupView: View {
    
    // MARK: - Properties -
    
    @ObservedObject private var nearbyManager = RXNearbyManager()
    
    let onFinish: (RXHardware) -> Void
    internal init(onFinish: @escaping (RXHardware) -> Void) {
        self.onFinish = onFinish
    }
    
    // MARK: - Body -
    
    var body: some View {
        let isDisplayingHardware = nearbyManager.shouldDisplayHardware
        return VStack {
            Text(isDisplayingHardware ? "Found Nearby Device" : "Searching For Devices")
                .font(.headline)
                .padding(.top, 20)
            
            ZStack {
                if isDisplayingHardware {
                    Text("Would you like to setup \(nearbyManager.queuedNearbyHardware[0].edition.rawValue)\nwith serial number \(nearbyManager.queuedNearbyHardware[0].serialNumber)?")
                        .multilineTextAlignment(.center)
                } else {
                    ActivityIndicator().scaleEffect(0.75)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 60)
           
            HStack {
                Button("    No    ", action: {
                    self.nearbyManager.firstQueuedHardwareNotOwners()
                })
                .padding()
                Button("   Yes!   ", action: {
                    self.onFinish(self.nearbyManager.queuedNearbyHardware[0])
                })
                .padding()
                
            }.opacity(isDisplayingHardware ? 1 : 0)
        }.frame(width: 220, height: 175)
    }
}

struct SNContentViewPreviews: PreviewProvider {
    static var previews: some View {
        SetupView(onFinish: { _ in })
    }
}
